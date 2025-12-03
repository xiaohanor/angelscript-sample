
UCLASS(Abstract)
class UGameplay_Character_Shared_Ragdoll_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	URagdollComponent RagdollComp;

	UPROPERTY(EditDefaultsOnly)
	FName MeshAttachSocketName = NAME_None;

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

	ABasicAICharacter AICharacter;

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

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RagdollComp = URagdollComponent::Get(HazeOwner);
		devCheck(RagdollComp != nullptr, f"Ragdoll SoundDef had missing RagdollComponent on {HazeOwner} - Need to be set as a DefaultComponent");

		AICharacter = Cast<ABasicAICharacter>(HazeOwner);	

		if(AICharacter.Mesh != nullptr)
			DefaultEmitter.AudioComponent.AttachToComponent(AICharacter.Mesh, MeshAttachSocketName);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		#if TEST
		if(RagdollComp == nullptr)
			return false;
		#endif

		return RagdollComp.bIsRagdolling;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !RagdollComp.bIsRagdolling;
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
	}

	UFUNCTION(BlueprintPure)
	void GetHandVelocitySpeedCombined(float&out Speed, float&out Delta)
	{
		Speed = CurrentHandFootSpeed;
		Delta = HandSpeedDelta;
	}
}