package mockdata

// import (
// 	"backend/pkg/model/authmodel"
// 	"time"

// 	"gorm.io/gorm"
// )

// func InsertMockData(db *gorm.DB) {
// 	product := []kaitanmodel.Product{
// 		{
// 			ID:          1,
// 			Name:        "Kaitan-Bloxfruit",
// 			Description: "Kaitan 6 หมัด",
// 			Price:       99,
// 			Stock:       100,
// 			CreateAt:    time.Now(),
// 			UpdateAt:    time.Now(),
// 			IsActive:    true,
// 		},
// 		{

// 			ID:          2,
// 			Name:        "Kaitan-Bloxfruit-CDK",
// 			Description: "ไก่ตัน 6 หมัด + ดาบคู่",
// 			Price:       199,
// 			Stock:       0,
// 			CreateAt:    time.Now(),
// 			UpdateAt:    time.Now(),
// 			IsActive:    false,
// 		},
// 	}

// 	users := []authmodel.User{
// 		{
// 			ID:       1,
// 			Username: "test01",
// 			Password: "test01",
// 			Email:    "test01@g.com",
// 		},
// 	}
// 	db.Create(&product)
// 	db.Create(&users)

// }
