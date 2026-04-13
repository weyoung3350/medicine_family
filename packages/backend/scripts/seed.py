"""种子脚本：生成完整演示数据，覆盖所有模块。

用法：
    cd packages/backend
    .venv/bin/python scripts/seed.py
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import date, time, timedelta, datetime, timezone

from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import hash_password
from app.models.user import User
from app.models.family import Family
from app.models.family_member import FamilyMember
from app.models.health_profile import HealthProfile
from app.models.medicine import Medicine
from app.models.medicine_inventory import MedicineInventory
from app.models.medication_plan import MedicationPlan
from app.models.medication_schedule import MedicationSchedule
from app.models.medication_log import MedicationLog
from app.models.medical_record import MedicalRecord
from app.models.notification import Notification
from app.models.ai_consultation import AiConsultation


def seed():
    engine = create_engine(settings.DATABASE_URL_SYNC)

    with Session(engine) as db:
        # 检查是否已有种子数据
        existing = db.execute(text("SELECT id FROM \"user\" WHERE phone = '13800138000'")).first()
        if existing:
            print("种子数据已存在，跳过。如需重建请先运行: .venv/bin/python scripts/seed.py --reset")
            if "--reset" in sys.argv:
                print("正在清除旧数据...")
                for table in [
                    "ai_consultation", "notification", "medical_record",
                    "medication_log", "medication_schedule", "medication_plan",
                    "medicine_inventory", "medicine", "health_profile",
                    "family_member", "family", '"user"',
                ]:
                    db.execute(text(f"DELETE FROM {table}"))
                db.commit()
                print("旧数据已清除，开始重建...")
            else:
                return

        today = date.today()

        # ══════════════════════════════════════════════════
        # 用户
        # ══════════════════════════════════════════════════
        user = User(phone="13800138000", nickname="小明", password_hash=hash_password("123456"), email="xiaoming@example.com")
        db.add(user)
        db.flush()
        print(f"✓ 用户: 13800138000 / 123456 (id={user.id})")

        # ══════════════════════════════════════════════════
        # 家庭
        # ══════════════════════════════════════════════════
        family = Family(name="王家", invite_code="DEMO2026", owner_id=user.id)
        db.add(family)
        db.flush()
        print(f"✓ 家庭: 王家 (邀请码=DEMO2026)")

        # ══════════════════════════════════════════════════
        # 成员 (4人)
        # ══════════════════════════════════════════════════
        self_member = FamilyMember(family_id=family.id, user_id=user.id, display_name="小明", role="owner")
        grandpa = FamilyMember(family_id=family.id, user_id=None, display_name="爷爷", role="dependent", relationship_label="祖父", managed_by=user.id)
        grandma = FamilyMember(family_id=family.id, user_id=None, display_name="奶奶", role="dependent", relationship_label="祖母", managed_by=user.id)
        mom = FamilyMember(family_id=family.id, user_id=None, display_name="妈妈", role="dependent", relationship_label="母亲", managed_by=user.id)
        db.add_all([self_member, grandpa, grandma, mom])
        db.flush()
        print(f"✓ 成员: 小明(自己), 爷爷, 奶奶, 妈妈")

        # ══════════════════════════════════════════════════
        # 健康档案
        # ══════════════════════════════════════════════════
        db.add(HealthProfile(
            member_id=grandpa.id, birth_date=date(1945, 3, 15), gender=1,
            height_cm=170, weight_kg=68, blood_type="A",
            medical_history=["高血压", "冠心病", "前列腺增生"],
            allergy_list=["青霉素"],
            chronic_meds=["硝苯地平", "阿司匹林", "非那雄胺"],
            notes="需要定期测血压，每季度复查心电图",
        ))
        db.add(HealthProfile(
            member_id=grandma.id, birth_date=date(1948, 6, 20), gender=2,
            height_cm=158, weight_kg=55, blood_type="O",
            medical_history=["糖尿病", "高血脂", "骨质疏松"],
            allergy_list=["磺胺类"],
            chronic_meds=["二甲双胍", "阿托伐他汀", "钙尔奇D"],
            notes="餐前血糖控制在7以下",
        ))
        db.add(HealthProfile(
            member_id=mom.id, birth_date=date(1975, 9, 8), gender=2,
            height_cm=162, weight_kg=58, blood_type="B",
            medical_history=["甲状腺结节"],
            allergy_list=[],
            chronic_meds=["左甲状腺素钠"],
            notes="每半年复查甲状腺功能",
        ))
        db.add(HealthProfile(
            member_id=self_member.id, birth_date=date(2009, 11, 25), gender=1,
            height_cm=175, weight_kg=62, blood_type="A",
            medical_history=[],
            allergy_list=["花粉"],
            chronic_meds=[],
            notes="季节性过敏性鼻炎",
        ))
        db.flush()
        print("✓ 健康档案: 爷爷/奶奶/妈妈/小明")

        # ══════════════════════════════════════════════════
        # 药品 + 库存 (10种)
        # ══════════════════════════════════════════════════
        medicines_data = [
            # (名称, 品牌, 单位, 分类, 规格, 剂型, 厂家, 适应症, 用法, 禁忌, 库存, 有效天数, 批号)
            ("硝苯地平控释片", "拜新同", "片", "处方药", "30mg×7片", "片剂",
             "拜耳医药", "用于高血压、心绞痛", "每日1次，每次1片，整片吞服", "低血压患者禁用", 14, 30, "BN2026031"),
            ("二甲双胍缓释片", "格华止", "片", "处方药", "0.5g×60片", "片剂",
             "中美上海施贵宝", "用于2型糖尿病", "每日2次，随餐服用", "肾功能不全者禁用", 60, 90, "GHZ20260215"),
            ("阿托伐他汀钙片", "立普妥", "片", "处方药", "20mg×7片", "片剂",
             "辉瑞制药", "用于高胆固醇血症", "每日1次，晚间服用", "孕妇禁用", 21, 120, "LP2026010"),
            ("阿司匹林肠溶片", "拜阿司匹灵", "片", "OTC", "100mg×30片", "片剂",
             "拜耳医药", "抗血小板聚集", "每日1次，餐后服用", "活动性出血者禁用", 30, 180, "BA2025121"),
            ("布洛芬缓释胶囊", "芬必得", "粒", "OTC", "0.3g×24粒", "胶囊",
             "中美天津史克", "用于缓解轻至中度疼痛", "每12小时1粒", "消化道溃疡患者慎用", 24, 60, "FB2026020"),
            ("左甲状腺素钠片", "优甲乐", "片", "处方药", "50μg×100片", "片剂",
             "默克公司", "甲状腺功能减退", "每日1次，晨起空腹服用", "未纠正的肾上腺功能不全禁用", 100, 365, "YJL2026011"),
            ("鱼油软胶囊", "汤臣倍健", "粒", "保健品", "1000mg×100粒", "胶囊",
             "汤臣倍健", "辅助降血脂", "每日1次，随餐服用", None, 100, 180, "TCB2026030"),
            ("钙尔奇D", "钙尔奇", "片", "OTC", "600mg×60片", "片剂",
             "惠氏制药", "补充钙和维生素D", "每日1次，随餐嚼服", None, 60, 365, "GEQ2026020"),
            ("阿莫西林胶囊", None, "粒", "处方药", "0.25g×24粒", "胶囊",
             "联邦制药", "用于敏感菌所致感染", "每8小时1次，每次1-2粒", "青霉素过敏者禁用", 24, 15, "LB2026040"),
            ("氯雷他定片", "开瑞坦", "片", "OTC", "10mg×6片", "片剂",
             "拜耳医药", "用于过敏性鼻炎、荨麻疹", "每日1次，1片", None, 6, 90, "KRT2026031"),
        ]

        meds = []
        for name, brand, unit, cat, spec, form, mfr, ind, usage, contra, qty, days, batch in medicines_data:
            med = Medicine(
                family_id=family.id, name=name, brand_name=brand,
                unit=unit, category=cat, specification=spec,
                dosage_form=form, manufacturer=mfr, indications=ind,
                usage_guide=usage, contraindications=contra,
                created_by=user.id,
            )
            db.add(med)
            db.flush()
            inv = MedicineInventory(
                medicine_id=med.id,
                batch_number=batch,
                total_quantity=qty, remaining_qty=max(qty - 5, 2),
                low_threshold=5,
                expiry_date=today + timedelta(days=days),
                status=2 if days <= 30 else 1,
                purchased_at=today - timedelta(days=30),
            )
            db.add(inv)
            meds.append(med)

        db.flush()
        print(f"✓ 药品: {len(meds)} 种 (含库存和批号)")

        # 索引 → 变量名映射
        m_nifedipine, m_metformin, m_atorvastatin, m_aspirin = meds[0], meds[1], meds[2], meds[3]
        m_ibuprofen, m_levothyroxine, m_fishoil, m_calcium = meds[4], meds[5], meds[6], meds[7]
        m_amoxicillin, m_loratadine = meds[8], meds[9]

        # ══════════════════════════════════════════════════
        # 服药计划 (6个)
        # ══════════════════════════════════════════════════

        # 爷爷: 硝苯地平 每日1次
        plan1 = MedicationPlan(
            member_id=grandpa.id, medicine_id=m_nifedipine.id,
            dosage_amount=1, dosage_unit="片", frequency_type="daily",
            meal_relation="after_meal", start_date=today - timedelta(days=30),
            grace_period_minutes=15, created_by=user.id, prescribed_by="李医生",
        )
        db.add(plan1); db.flush()
        db.add(MedicationSchedule(plan_id=plan1.id, time_of_day=time(8, 0), label="早餐后", sort_order=0))

        # 爷爷: 阿司匹林 每日1次
        plan2 = MedicationPlan(
            member_id=grandpa.id, medicine_id=m_aspirin.id,
            dosage_amount=1, dosage_unit="片", frequency_type="daily",
            meal_relation="after_meal", start_date=today - timedelta(days=60),
            grace_period_minutes=30, created_by=user.id, prescribed_by="李医生",
        )
        db.add(plan2); db.flush()
        db.add(MedicationSchedule(plan_id=plan2.id, time_of_day=time(12, 30), label="午餐后", sort_order=0))

        # 奶奶: 二甲双胍 每日2次
        plan3 = MedicationPlan(
            member_id=grandma.id, medicine_id=m_metformin.id,
            dosage_amount=1, dosage_unit="片", frequency_type="daily",
            meal_relation="with_meal", start_date=today - timedelta(days=30),
            grace_period_minutes=15, created_by=user.id, prescribed_by="张医生",
        )
        db.add(plan3); db.flush()
        db.add(MedicationSchedule(plan_id=plan3.id, time_of_day=time(7, 30), label="早餐时", sort_order=0))
        db.add(MedicationSchedule(plan_id=plan3.id, time_of_day=time(18, 30), label="晚餐时", sort_order=1))

        # 奶奶: 阿托伐他汀 每晚1次
        plan4 = MedicationPlan(
            member_id=grandma.id, medicine_id=m_atorvastatin.id,
            dosage_amount=1, dosage_unit="片", frequency_type="daily",
            meal_relation="anytime", start_date=today - timedelta(days=45),
            grace_period_minutes=30, created_by=user.id, prescribed_by="张医生",
        )
        db.add(plan4); db.flush()
        db.add(MedicationSchedule(plan_id=plan4.id, time_of_day=time(21, 0), label="睡前", sort_order=0))

        # 奶奶: 钙尔奇D 每日1次
        plan5 = MedicationPlan(
            member_id=grandma.id, medicine_id=m_calcium.id,
            dosage_amount=1, dosage_unit="片", frequency_type="daily",
            meal_relation="with_meal", start_date=today - timedelta(days=20),
            grace_period_minutes=30, created_by=user.id,
        )
        db.add(plan5); db.flush()
        db.add(MedicationSchedule(plan_id=plan5.id, time_of_day=time(12, 0), label="午餐时", sort_order=0))

        # 妈妈: 优甲乐 每日1次
        plan6 = MedicationPlan(
            member_id=mom.id, medicine_id=m_levothyroxine.id,
            dosage_amount=1, dosage_unit="片", frequency_type="daily",
            meal_relation="empty_stomach", start_date=today - timedelta(days=90),
            grace_period_minutes=15, created_by=user.id, prescribed_by="王医生",
        )
        db.add(plan6); db.flush()
        db.add(MedicationSchedule(plan_id=plan6.id, time_of_day=time(6, 30), label="晨起空腹", sort_order=0))

        db.flush()
        plans = [plan1, plan2, plan3, plan4, plan5, plan6]
        print(f"✓ 服药计划: {len(plans)} 个")

        # ══════════════════════════════════════════════════
        # 历史服药日志 (过去7天)
        # ══════════════════════════════════════════════════
        log_count = 0
        for day_offset in range(7, 0, -1):
            log_date = today - timedelta(days=day_offset)
            for plan in plans:
                for sched in plan.schedules:
                    # 模拟不同的服药状态
                    if day_offset == 3 and plan == plan3:
                        status = "missed"  # 奶奶3天前漏服一次二甲双胍
                    elif day_offset == 5 and plan == plan2:
                        status = "skipped"  # 爷爷5天前跳过一次阿司匹林
                    else:
                        status = "taken"
                    log = MedicationLog(
                        schedule_id=sched.id, plan_id=plan.id,
                        member_id=plan.member_id,
                        scheduled_date=log_date,
                        scheduled_time=sched.time_of_day,
                        status=status,
                        taken_at=datetime.combine(log_date, sched.time_of_day, tzinfo=timezone.utc) if status == "taken" else None,
                        quantity_taken=plan.dosage_amount if status == "taken" else None,
                        recorded_by=user.id,
                        skip_reason="胃不舒服" if status == "skipped" else None,
                    )
                    db.add(log)
                    log_count += 1
        db.flush()
        print(f"✓ 服药日志: {log_count} 条 (过去7天)")

        # ══════════════════════════════════════════════════
        # 病历 (3条)
        # ══════════════════════════════════════════════════
        records = [
            MedicalRecord(
                family_id=family.id, member_id=grandpa.id,
                hospital="浙江大学医学院附属第一医院", department="心内科", doctor="李建国",
                visit_date=today - timedelta(days=15),
                diagnosis="高血压3级，冠心病", chief_complaint="头晕、胸闷一周",
                present_illness="患者近一周反复出现头晕、胸闷，血压波动于150-170/90-100mmHg",
                prescriptions={"items": [
                    {"name": "硝苯地平控释片", "dosage": "30mg", "frequency": "每日1次"},
                    {"name": "阿司匹林肠溶片", "dosage": "100mg", "frequency": "每日1次"},
                ]},
                examinations="心电图：ST段压低；血压：168/95mmHg",
                doctor_advice="低盐低脂饮食，规律服药，2周后复查",
                created_by=user.id,
            ),
            MedicalRecord(
                family_id=family.id, member_id=grandma.id,
                hospital="浙江省人民医院", department="内分泌科", doctor="张丽华",
                visit_date=today - timedelta(days=10),
                diagnosis="2型糖尿病，高脂血症", chief_complaint="口干、多饮2个月",
                present_illness="患者近2月口渴明显，饮水量增加，空腹血糖8.5mmol/L",
                prescriptions={"items": [
                    {"name": "二甲双胍缓释片", "dosage": "0.5g", "frequency": "每日2次"},
                    {"name": "阿托伐他汀钙片", "dosage": "20mg", "frequency": "每晚1次"},
                ]},
                examinations="空腹血糖：8.5mmol/L，HbA1c：7.8%，TC：6.2mmol/L",
                doctor_advice="控制饮食，适量运动，3个月后复查糖化血红蛋白",
                created_by=user.id,
            ),
            MedicalRecord(
                family_id=family.id, member_id=mom.id,
                hospital="杭州市第一人民医院", department="甲乳外科", doctor="王伟",
                visit_date=today - timedelta(days=45),
                diagnosis="甲状腺结节（良性）", chief_complaint="体检发现甲状腺结节",
                present_illness="体检B超发现甲状腺左叶结节，约8mm，TI-RADS 3级",
                prescriptions={"items": [
                    {"name": "左甲状腺素钠片", "dosage": "50μg", "frequency": "每日1次"},
                ]},
                examinations="甲状腺B超：左叶结节8×6mm，边界清晰；FT3、FT4正常，TSH 5.2mIU/L",
                doctor_advice="定期复查甲状腺功能和B超，每6个月一次",
                created_by=user.id,
            ),
        ]
        db.add_all(records)
        db.flush()
        print(f"✓ 病历: {len(records)} 条")

        # ══════════════════════════════════════════════════
        # 通知 (8条，混合类型和已读状态)
        # ══════════════════════════════════════════════════
        notifications = [
            Notification(user_id=user.id, title="服药提醒", body="爷爷的硝苯地平控释片该服用了（08:00 早餐后）", type="reminder", is_read=False),
            Notification(user_id=user.id, title="服药提醒", body="奶奶的二甲双胍缓释片该服用了（07:30 早餐时）", type="reminder", is_read=False),
            Notification(user_id=user.id, title="漏服提醒", body="奶奶昨天的阿托伐他汀钙片（21:00 睡前）未服用", type="alert", is_read=False),
            Notification(user_id=user.id, title="临期预警", body="硝苯地平控释片将在30天内到期，请及时补充", type="alert", is_read=True),
            Notification(user_id=user.id, title="库存不足", body="阿莫西林胶囊库存仅剩19粒，低于预警值", type="alert", is_read=True),
            Notification(user_id=user.id, title="复查提醒", body="爷爷的心内科复查日期临近（2周前就诊，建议2周后复查）", type="info", is_read=False),
            Notification(user_id=user.id, title="健康小贴士", body="秋冬季节，老年人注意保暖，预防心脑血管意外", type="info", is_read=True),
            Notification(user_id=user.id, title="家庭报告", body="本周家庭整体服药依从率92%，爷爷100%，奶奶85%", type="info", is_read=True),
        ]
        db.add_all(notifications)
        db.flush()
        print(f"✓ 通知: {len(notifications)} 条")

        # ══════════════════════════════════════════════════
        # AI 问诊记录 (2条)
        # ══════════════════════════════════════════════════
        ai_records = [
            AiConsultation(
                user_id=user.id, family_id=family.id, member_id=grandpa.id,
                type="interaction_check",
                input_text="爷爷同时吃硝苯地平和阿司匹林，有没有药物相互作用？",
                ai_model="qwen-max",
                result_summary="硝苯地平与阿司匹林一般可以合用，但需注意监测血压和出血风险。",
            ),
            AiConsultation(
                user_id=user.id, family_id=family.id, member_id=grandma.id,
                type="medication_guide",
                input_text="奶奶的二甲双胍应该饭前还是饭后吃？",
                ai_model="qwen-max",
                result_summary="二甲双胍缓释片建议随餐服用，可减少胃肠道不良反应。如忘记随餐服用，可在餐后补服。",
            ),
        ]
        db.add_all(ai_records)

        db.commit()
        print()
        print("=" * 60)
        print("种子数据创建完成！")
        print(f"  演示账号: 13800138000")
        print(f"  密码: 123456")
        print(f"  家庭邀请码: DEMO2026")
        print()
        print("  数据概览:")
        print(f"    成员: 4 人 (小明/爷爷/奶奶/妈妈)")
        print(f"    健康档案: 4 份")
        print(f"    药品: {len(meds)} 种 (含库存)")
        print(f"    服药计划: {len(plans)} 个")
        print(f"    服药日志: {log_count} 条 (7天)")
        print(f"    病历: {len(records)} 条")
        print(f"    通知: {len(notifications)} 条")
        print(f"    AI问诊: {len(ai_records)} 条")
        print("=" * 60)

    engine.dispose()


if __name__ == "__main__":
    seed()
