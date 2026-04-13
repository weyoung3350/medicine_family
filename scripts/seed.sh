#!/bin/bash
# 模拟数据种子脚本
API="http://localhost:3000/api/v1"

echo "=== 1. 注册用户 ==="
RES=$(curl -s -X POST "$API/auth/register" -H "Content-Type: application/json" -d '{
  "phone": "13800138000",
  "nickname": "小明",
  "password": "123456"
}')
TOKEN=$(echo $RES | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
echo "Token: ${TOKEN:0:20}..."

AUTH="Authorization: Bearer $TOKEN"

echo ""
echo "=== 2. 创建家庭 ==="
FAM=$(curl -s -X POST "$API/families" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "name": "王家"
}')
FAM_ID=$(echo $FAM | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "家庭ID: ${FAM_ID:0:8}..."

echo ""
echo "=== 3. 添加家庭成员(爷爷) ==="
MEM1=$(curl -s -X POST "$API/families/$FAM_ID/members" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "displayName": "爷爷",
  "relationship": "祖父",
  "healthProfile": {
    "birthDate": "1950-03-15",
    "gender": 1,
    "medicalHistory": ["高血压", "冠心病"],
    "allergyList": ["青霉素"]
  }
}')
MEM1_ID=$(echo $MEM1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "爷爷ID: ${MEM1_ID:0:8}..."

echo ""
echo "=== 4. 添加家庭成员(奶奶) ==="
MEM2=$(curl -s -X POST "$API/families/$FAM_ID/members" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "displayName": "奶奶",
  "relationship": "祖母",
  "healthProfile": {
    "birthDate": "1952-08-22",
    "gender": 2,
    "medicalHistory": ["糖尿病", "高血脂"],
    "allergyList": ["磺胺类"]
  }
}')
MEM2_ID=$(echo $MEM2 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "奶奶ID: ${MEM2_ID:0:8}..."

# 获取小明自己的member ID
echo ""
echo "=== 5. 获取成员列表 ==="
MEMBERS=$(curl -s "$API/families/$FAM_ID/members" -H "$AUTH")
MY_ID=$(echo $MEMBERS | python3 -c "import sys,json; ms=json.load(sys.stdin); print([m['id'] for m in ms if m['role']=='owner'][0])" 2>/dev/null)
echo "小明ID: ${MY_ID:0:8}..."

# 给小明也加健康档案
curl -s -X PUT "$API/families/$FAM_ID/members/$MY_ID/health" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "birthDate": "1995-06-10",
  "gender": 1,
  "heightCm": 175,
  "weightKg": 70,
  "bloodType": "A",
  "medicalHistory": [],
  "allergyList": ["花粉"],
  "chronicMeds": []
}' > /dev/null

echo ""
echo "=== 6. 添加药品 ==="

# 布洛芬
MED1=$(curl -s -X POST "$API/families/$FAM_ID/medicines" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "name": "布洛芬缓释胶囊",
  "brandName": "芬必得",
  "dosageForm": "胶囊",
  "specification": "0.3g*20粒/盒",
  "unit": "粒",
  "manufacturer": "中美天津史克制药",
  "category": "OTC",
  "indications": "用于缓解轻至中度疼痛如头痛、关节痛、偏头痛、牙痛、肌肉痛、神经痛、痛经。也用于普通感冒或流行性感冒引起的发热。",
  "contraindications": "对本品过敏者禁用；孕妇及哺乳期妇女禁用",
  "usageGuide": "口服。成人每次1粒，每日2次（早晚各一次）。饭后服用，温水送下。"
}')
MED1_ID=$(echo $MED1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "布洛芬ID: ${MED1_ID:0:8}..."

# 降压药
MED2=$(curl -s -X POST "$API/families/$FAM_ID/medicines" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "name": "硝苯地平控释片",
  "brandName": "拜新同",
  "dosageForm": "片剂",
  "specification": "30mg*7片/盒",
  "unit": "片",
  "manufacturer": "拜耳医药",
  "category": "处方药",
  "indications": "高血压、冠心病、慢性稳定型心绞痛的治疗",
  "contraindications": "心源性休克、严重主动脉瓣狭窄者禁用",
  "usageGuide": "口服，每日一次，每次一片（30mg）。整片吞服，不可掰开或咀嚼。建议每天早晨固定时间服用。"
}')
MED2_ID=$(echo $MED2 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "降压药ID: ${MED2_ID:0:8}..."

# 二甲双胍
MED3=$(curl -s -X POST "$API/families/$FAM_ID/medicines" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "name": "盐酸二甲双胍片",
  "brandName": "格华止",
  "dosageForm": "片剂",
  "specification": "0.5g*20片/盒",
  "unit": "片",
  "manufacturer": "中美上海施贵宝",
  "category": "处方药",
  "indications": "用于单纯饮食控制不满意的2型糖尿病患者",
  "contraindications": "肾功能不全、肝功能不全者禁用",
  "usageGuide": "口服，每次1片，每日2-3次，随餐或餐后服用，以减少胃肠道反应。"
}')
MED3_ID=$(echo $MED3 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "二甲双胍ID: ${MED3_ID:0:8}..."

# 鱼油
MED4=$(curl -s -X POST "$API/families/$FAM_ID/medicines" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "name": "深海鱼油软胶囊",
  "brandName": "汤臣倍健",
  "dosageForm": "胶囊",
  "specification": "1000mg*100粒/瓶",
  "unit": "粒",
  "manufacturer": "汤臣倍健股份有限公司",
  "category": "保健品",
  "indications": "辅助降血脂，补充EPA和DHA",
  "contraindications": "凝血功能障碍者慎用",
  "usageGuide": "每日2次，每次1粒，随餐服用。"
}')
MED4_ID=$(echo $MED4 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "鱼油ID: ${MED4_ID:0:8}..."

# 阿莫西林
MED5=$(curl -s -X POST "$API/families/$FAM_ID/medicines" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "name": "阿莫西林胶囊",
  "brandName": "阿莫仙",
  "dosageForm": "胶囊",
  "specification": "0.25g*24粒/盒",
  "unit": "粒",
  "manufacturer": "珠海联邦制药",
  "category": "处方药",
  "indications": "敏感菌所致的呼吸道感染、泌尿生殖道感染、皮肤软组织感染等",
  "contraindications": "青霉素过敏者禁用",
  "usageGuide": "口服，每次2粒，每8小时一次，饭后服用。疗程一般5-7天。"
}')
MED5_ID=$(echo $MED5 | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
echo "阿莫西林ID: ${MED5_ID:0:8}..."

echo ""
echo "=== 7. 添加库存 ==="

# 布洛芬 - 库存正常
curl -s -X POST "$API/families/$FAM_ID/medicines/$MED1_ID/inventory" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "totalQuantity": 20, "batchNumber": "B20260301", "expiryDate": "2028-03-01", "lowThreshold": 5
}' > /dev/null
echo "布洛芬: 20粒, 2028-03过期"

# 降压药 - 库存低
curl -s -X POST "$API/families/$FAM_ID/medicines/$MED2_ID/inventory" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "totalQuantity": 7, "remainingQty": 3, "batchNumber": "B20260215", "expiryDate": "2027-06-15", "lowThreshold": 5
}' > /dev/null
echo "降压药: 仅剩3片(低库存!), 2027-06过期"

# 二甲双胍 - 正常
curl -s -X POST "$API/families/$FAM_ID/medicines/$MED3_ID/inventory" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "totalQuantity": 20, "batchNumber": "B20260110", "expiryDate": "2027-12-01", "lowThreshold": 5
}' > /dev/null
echo "二甲双胍: 20片, 2027-12过期"

# 鱼油 - 正常
curl -s -X POST "$API/families/$FAM_ID/medicines/$MED4_ID/inventory" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "totalQuantity": 100, "batchNumber": "B20260401", "expiryDate": "2028-04-01", "lowThreshold": 10
}' > /dev/null
echo "鱼油: 100粒, 2028-04过期"

# 阿莫西林 - 临期
curl -s -X POST "$API/families/$FAM_ID/medicines/$MED5_ID/inventory" -H "Content-Type: application/json" -H "$AUTH" -d '{
  "totalQuantity": 24, "batchNumber": "B20240801", "expiryDate": "2026-05-01", "lowThreshold": 5
}' > /dev/null
echo "阿莫西林: 24粒, 2026-05过期(临期!)"

echo ""
echo "=== 8. 创建服药计划 ==="

# 爷爷 - 降压药 每天早晨
PLAN1=$(curl -s -X POST "$API/families/$FAM_ID/members/$MEM1_ID/plans" -H "Content-Type: application/json" -H "$AUTH" -d "{
  \"medicineId\": \"$MED2_ID\",
  \"dosageAmount\": 1,
  \"dosageUnit\": \"片\",
  \"frequencyType\": \"daily\",
  \"mealRelation\": \"before_meal\",
  \"startDate\": \"2026-01-01\",
  \"gracePeriodMinutes\": 15,
  \"schedules\": [{\"timeOfDay\": \"07:30\", \"label\": \"早餐前\"}]
}")
echo "爷爷: 降压药 每天07:30早餐前"

# 奶奶 - 二甲双胍 每天三次
PLAN2=$(curl -s -X POST "$API/families/$FAM_ID/members/$MEM2_ID/plans" -H "Content-Type: application/json" -H "$AUTH" -d "{
  \"medicineId\": \"$MED3_ID\",
  \"dosageAmount\": 1,
  \"dosageUnit\": \"片\",
  \"frequencyType\": \"daily\",
  \"mealRelation\": \"after_meal\",
  \"startDate\": \"2026-01-01\",
  \"gracePeriodMinutes\": 30,
  \"schedules\": [
    {\"timeOfDay\": \"08:00\", \"label\": \"早餐后\"},
    {\"timeOfDay\": \"12:30\", \"label\": \"午餐后\"},
    {\"timeOfDay\": \"18:30\", \"label\": \"晚餐后\"}
  ]
}")
echo "奶奶: 二甲双胍 每天三次(08:00/12:30/18:30)"

# 小明 - 鱼油 每天一次
PLAN3=$(curl -s -X POST "$API/families/$FAM_ID/members/$MY_ID/plans" -H "Content-Type: application/json" -H "$AUTH" -d "{
  \"medicineId\": \"$MED4_ID\",
  \"dosageAmount\": 1,
  \"dosageUnit\": \"粒\",
  \"frequencyType\": \"daily\",
  \"mealRelation\": \"with_meal\",
  \"startDate\": \"2026-03-01\",
  \"gracePeriodMinutes\": 30,
  \"schedules\": [{\"timeOfDay\": \"08:00\", \"label\": \"早餐时\"}]
}")
echo "小明: 鱼油 每天08:00早餐时"

# 爷爷 - 布洛芬 临时(关节痛)
PLAN4=$(curl -s -X POST "$API/families/$FAM_ID/members/$MEM1_ID/plans" -H "Content-Type: application/json" -H "$AUTH" -d "{
  \"medicineId\": \"$MED1_ID\",
  \"dosageAmount\": 1,
  \"dosageUnit\": \"粒\",
  \"frequencyType\": \"daily\",
  \"mealRelation\": \"after_meal\",
  \"startDate\": \"2026-04-10\",
  \"endDate\": \"2026-04-17\",
  \"prescribedBy\": \"李医生\",
  \"notes\": \"关节痛，服用一周\",
  \"gracePeriodMinutes\": 15,
  \"schedules\": [
    {\"timeOfDay\": \"08:00\", \"label\": \"早餐后\"},
    {\"timeOfDay\": \"20:00\", \"label\": \"晚餐后\"}
  ]
}")
echo "爷爷: 布洛芬 每天两次(04/10-04/17, 李医生开具)"

echo ""
echo "=== 完成! ==="
echo "登录账号: 13800138000"
echo "密码: 123456"
echo "家庭: 王家 (邀请码见页面)"
echo "成员: 小明(自己) + 爷爷 + 奶奶"
echo "药品: 布洛芬/降压药/二甲双胍/鱼油/阿莫西林"
echo "预警: 降压药库存低(3片) + 阿莫西林临期(5月过期)"
