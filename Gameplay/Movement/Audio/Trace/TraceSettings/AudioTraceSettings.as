
// USTRUCT(Meta = ComposedStruct)
// struct FAudioTraceSettingsData
// {	
// 	UPROPERTY()
// 	EFootstepTraceType TraceType = EFootstepTraceType::Sphere;

// 	UPROPERTY()
// 	float MinLength = 1.0;

// 	UPROPERTY()
// 	float MaxLength = 5.0;

// 	UPROPERTY()
// 	float MinRequiredVelo = 5.0;

// 	UPROPERTY()
// 	float MaxVelo = 30.0;
	
// 	UPROPERTY()
// 	float TriggerCooldown= 0.25;

// 	UPROPERTY()
// 	float SlidingDelay = 0.1;

// 	UPROPERTY()
// 	int32 MakeUpGain = 0;

// 	UPROPERTY()
// 	int32 Pitch = 0;
// };

// UCLASS(NotBlueprintable, Meta = (ComposeSettingsOnto = "UAudioTraceSettings"))
// class UAudioTraceSettings : UHazeAudioTraceSettings
// {
// 	UPROPERTY(EditDefaultsOnly, EditFixedSize, Meta = (ShowOnlyInnerProperties))
// 	TMap<EHandType, FAudioTraceSettingsData> Hand;
// 	default Hand.FindOrAdd(EHandType::Left);
// 	default Hand.FindOrAdd(EHandType::Right);

// 	UPROPERTY(EditDefaultsOnly, EditFixedSize, Meta = (ShowOnlyInnerProperties))
// 	TMap<EFootType, FAudioTraceSettingsData> Foot;
// 	default Foot.FindOrAdd(EFootType::Left);
// 	default Foot.FindOrAdd(EFootType::Right);

// 	// // Left Hand
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Shape")
// 	// EFootstepTraceType LeftHandTraceType = EFootstepTraceType::Sphere;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Min Trace Length")
// 	// float LeftHandMinLength = 1.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Max Trace Length")
// 	// float LeftHandMaxLength = 5.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Min Required Velocity")
// 	// float LeftHandMinRequiredVelo = 5.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Max Hand Velocity")
// 	// float LeftHandMaxVelo = 30.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Trigger Cooldown")
// 	// float LeftHandTriggerCooldown= 0.25;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Sliding Delay")
// 	// float LeftHandSlidingDelay = 0.1;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Make-Up Gain")
// 	// int32 LeftHandMakeUpGain = 0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Hand", DisplayName = "Pitch")
// 	// int32 LeftHandPitch = 0;
	
// 	// // Right Hand
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Shape")
// 	// EFootstepTraceType RightHandTraceType = EFootstepTraceType::Sphere;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Min Trace Length")
// 	// float RightHandMinLength = 1.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Max Trace Length")
// 	// float RightHandMaxLength = 1.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Min Required Velocity")
// 	// float RightHandMinRequiredVelo = 5.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Max Hand Velocity")
// 	// float RightHandMaxVelo = 30.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Trigger Cooldown")
// 	// float RightHandTriggerCooldown= 0.25;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Sliding Delay")
// 	// float RightHandSlidingDelay = 0.1;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Make-Up Gain")
// 	// int32 RightHandMakeUpGain = 0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Hand", DisplayName = "Pitch")
// 	// int32 RightHandPitch = 0;
	
// 	// // Left Foot
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Shape")
// 	// EFootstepTraceType LeftFootTraceType = EFootstepTraceType::Sphere;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Min Trace Length")
// 	// float LeftFootMinLength = 0.5;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Max Trace Length")
// 	// float LeftFootMaxLength = 5.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Min Required Velocity")
// 	// float LeftFootMinRequiredVelo = 0.5;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Trigger Cooldown")
// 	// float LeftFootTriggerCooldown = 0.1;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Max Foot Velocity")
// 	// float LeftFootMaxVelo = 600;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Make-Up Gain")
// 	// int32 LeftFootMakeUpGain = 0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Left Foot", DisplayName = "Pitch")
// 	// int32 LeftFootPitch = 0;
	
// 	// // Right Foot
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Shape")
// 	// EFootstepTraceType RightFootTraceType = EFootstepTraceType::Sphere;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Min Trace Length")
// 	// float RightFootMinLength = 1.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Max Trace Length")
// 	// float RightFootMaxLength = 1.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Min Required Velocity")
// 	// float RightFootMinRequiredVelo = 5.0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Trigger Cooldown")
// 	// float RightFootTriggerCooldown = 0.1;
		
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Max Foot Velocity")
// 	// float RightFootMaxVelo = 600;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Make-Up Gain")
// 	// int32 RightFootMakeUpGain = 0;
	
// 	// UPROPERTY(EditDefaultsOnly, Category = "Right Foot", DisplayName = "Pitch")
// 	// int32 RightFootPitch = 0;
// }