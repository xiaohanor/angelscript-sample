
UCLASS(Abstract)
class UCharacter_AI_Shared_Basic_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UBasicAIAnimationComponent AnimationComp;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UBasicBehaviourComponent BehaviourComp;

	UPROPERTY(BlueprintReadOnly)
	ABasicAICharacter AICharacter;

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	FName HeadSocketName = n"Head";

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	FName LeftHandSocketName = n"LeftHand";

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	FName RightHandSocketName = n"RightHand";

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	FName LeftFootSocketName = n"LeftFoot";

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	FName RightFootSocketName = n"RightFoot";

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	float MaxHandSpeed = 250.0;

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	float MaxFootSpeed = 250.0;

	UPROPERTY(EditDefaultsOnly, Category = Animation)
	float MaxHandSpeedDelta = 0.15;

	private FVector CachedActorLocation;
	private FVector CachedHeadLocation;
	private FVector CachedLeftHandLocation;
	private FVector CachedRightHandLocation;
	private FVector CachedLeftFootLocation;
	private FVector CachedRightFootLocation;

	private float CachedLeftHandSpeed = 0.0;
	private float CachedRightHandSpeed = 0.0;
	private float CachedLeftFootSpeed = 0.0;
	private float CachedRightFootSpeed = 0.0;

	private float CurrentHandFootSpeed = 0.0;

	private float PreviousHandSpeed = 0.0;
	private float HandSpeedDelta = 0.0;

	private URagdollComponent RagdollComp;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(RagdollComp != nullptr && RagdollComp.bIsRagdolling)
			return false;

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(RagdollComp != nullptr && RagdollComp.bIsRagdolling)
			return true;

		return false;
	}

	FVector GetLeftHandLocation() const property
	{
		return AICharacter.Mesh.GetSocketLocation(LeftHandSocketName);
	}

	FVector GetRightHandLocation() const property
	{
		return AICharacter.Mesh.GetSocketLocation(RightHandSocketName);
	}

	FVector GetLeftFootLocation() const property
	{
		return AICharacter.Mesh.GetSocketLocation(LeftFootSocketName);
	}

	FVector GetRightFootLocation() const property
	{
		return AICharacter.Mesh.GetSocketLocation(RightFootSocketName);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AICharacter = Cast<ABasicAICharacter>(HazeOwner);
		if(AICharacter == nullptr)
			devCheck(false, "AI Movement SoundDef was put on a non-AI actor!");

		AnimationComp = AICharacter.AnimComp;
		BehaviourComp = AICharacter.BehaviourComponent;
		RagdollComp = URagdollComponent::Get(AICharacter);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector ActorLocation = HazeOwner.ActorLocation;
		const FVector ActorVelo = ActorLocation - CachedActorLocation;

		const FVector LeftHandVelo = (LeftHandLocation - CachedLeftHandLocation) - ActorVelo;
		CachedLeftHandSpeed = Math::Min(1, (LeftHandVelo.Size() / DeltaSeconds) / MaxHandSpeed);

		const FVector RightHandVelo = (RightHandLocation - CachedRightHandLocation) - ActorVelo;
		CachedRightHandSpeed = Math::Min(1, (RightHandVelo.Size() / DeltaSeconds) / MaxHandSpeed);

		const FVector LeftFootVelo = (LeftFootLocation - CachedLeftFootLocation) - ActorVelo;
		CachedLeftFootSpeed = Math::Min(1, (LeftFootVelo.Size() / DeltaSeconds) / MaxFootSpeed);

		const FVector RightFootVelo = (RightFootLocation - CachedRightFootLocation) - ActorVelo;
		CachedRightFootSpeed = Math::Min(1, (RightFootVelo.Size() / DeltaSeconds) / MaxFootSpeed);

		CurrentHandFootSpeed = (CachedLeftHandSpeed + CachedRightHandSpeed + CachedLeftFootSpeed + CachedRightFootSpeed) / 4;
		const float CurrentHandSpeed = (CachedLeftHandSpeed + CachedRightHandSpeed) / 2;
		HandSpeedDelta = Math::Clamp((CurrentHandSpeed - PreviousHandSpeed) / MaxHandSpeedDelta, -1.0, 1.0);

		CachedLeftHandLocation = LeftHandLocation;
		CachedRightHandLocation = RightHandLocation;
		PreviousHandSpeed = CurrentHandSpeed;

		CachedLeftFootLocation = LeftFootLocation;
		CachedRightFootLocation = RightFootLocation;	

		CachedActorLocation = ActorLocation;

		#if TEST
		Log();
		#endif
	}

	#if TEST
	void Log()
	{
		auto TemporalLog = TEMPORAL_LOG(AICharacter, "Audio");
		TemporalLog.Value("Tag: ", AICharacter.MoveAudioComp.GetActiveMovementTag(n"AI_Basic_Movement")).
		Value("Animation;Head Socket: ", HeadSocketName).
		Value("Animation;Left Hand Socket: ", LeftHandSocketName).
		Value("Animation;Right Hand Socket: ", RightHandSocketName).
		Value("Animation;Left Foot Socket: ", LeftFootSocketName).
		Value("Animation;Right Foot Socket: ", RightFootSocketName);

		float HandFootSpeed = 0.0;
		float HandDelta = 0.0;
		GetHandFootVelocitySpeedCombined(HandFootSpeed, HandDelta);

		TemporalLog.Value("Movement; Speed Forward", AnimationComp.SpeedForward).
		Value("Movement; Speed Sideways", AnimationComp.SpeedRight).
		Value("Movement; Speed Vertical", AnimationComp.SpeedUp).
		Value("Combined Hand/Foot Speed: ", HandFootSpeed).
		Value("Combined Hand Delta: ", HandDelta);
	}
	#endif

	UFUNCTION(BlueprintPure)
	void GetHandFootVelocitySpeedCombined(float&out Speed, float&out Delta)
	{
		Speed = CurrentHandFootSpeed;
		Delta = HandSpeedDelta;
	}

}