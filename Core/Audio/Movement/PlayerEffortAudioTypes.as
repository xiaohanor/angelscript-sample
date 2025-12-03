// enum EEffortAudioCategory
// {
// 	NONE = 0,
// 	Low = 1,
// 	High = 2,
// 	Critical = 3,
// 	MAX = 4	
// }

// enum EEffortAudioPushType
// {
// 	NONE,
// 	Immediate,
// 	Continuous
// }

// enum EEffortAudioState
// {
// 	NONE,
// 	Pending,
// 	Handling,
// 	Consumed,
// 	Recovered
// }

// USTRUCT(Meta = (ComposedStruct))
// struct FEffortData
// {
// 	UPROPERTY()
// 	EEffortAudioCategory Category = EEffortAudioCategory::NONE;

// 	UPROPERTY(meta = (EditCondition = "Category != EEffortAudioCategory::NONE"))
// 	EEffortAudioPushType PushType = EEffortAudioPushType::Immediate;

// 	// How quickly does the character become exerted (out of breath)
// 	UPROPERTY(meta = (UIMin = 0, UIMax = 100))
// 	float EffortFactor = 25.0;

// 	UPROPERTY()
// 	UCurveFloat EffortCurve = nullptr;

// 	UPROPERTY()
// 	UCurveFloat RecoveryCurve = nullptr;

// 	UPROPERTY(NotVisible)
// 	float EffortTotal = 0.0;

// 	// How quickly does the character recover from exertion (catches their breath)
// 	UPROPERTY(meta = (UIMin = 0, UIMax = 100))
// 	float RecoveryFactor = 1.0;

// 	EEffortAudioState State = EEffortAudioState::NONE;
// }

// struct FRecoveryEffortDatas
// {
// 	UPROPERTY()
// 	TArray<FEffortData> Data;
// }