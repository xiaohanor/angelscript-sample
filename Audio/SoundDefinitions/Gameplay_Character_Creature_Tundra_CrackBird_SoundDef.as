
UCLASS(Abstract)
class UGameplay_Character_Creature_Tundra_CrackBird_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void CatapultLand(){}

	UFUNCTION(BlueprintEvent)
	void CatapultLaunch(){}

	UFUNCTION(BlueprintEvent)
	void PlaceInNest(FTundraBigCrackBirdPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void LiftFromNest(FTundraBigCrackBirdPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnExplode(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerStuck(FTundraBigCrackBirdPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHitWall(){}

	UFUNCTION(BlueprintEvent)
	void OnHitWithLog(){}

	/* END OF AUTO-GENERATED CODE */

	ABigCrackBird CrackBird;
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	FVector GetLeftWingLocation() const property
	{
		return SkelMeshComp.GetSocketLocation(n"LeftHand");
	}

	FVector GetRightWingLocation() const property
	{
		return SkelMeshComp.GetSocketLocation(n"RightHand");
	}

	FRotator GetHeadRotation() const property
	{
		return SkelMeshComp.GetSocketRotation(n"Head");
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CrackBird = Cast<ABigCrackBird>(HazeOwner);
		SkelMeshComp = UHazeSkeletalMeshComponentBase::Get(HazeOwner);
	}

	private FVector LastLeftWingLocation;	
	private FVector LastRightWingLocation;	
	private FRotator LastHeadRotation;

	private float CachedBodyMovementSpeed = 0.0;
	private float CachedWingMovementSpeed = 0.0;
	private float CachedBeakRelativeRotation = 0.0;

	private const float MAX_WING_MOVEMENT_SPEED = 1500;
	private const float MAX_HEAD_MOVEMENT_SPEED = 0.05;
	private const float MAX_BEAK_OPEN_RELATIVE_PITCH = -30.0;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector CurrentLeftWingLocation = LeftWingLocation;
		const FVector CurrentRightWingLocation = RightWingLocation;
		const FRotator CurrentHeadRotation = HeadRotation;	

		const FVector LeftWingVelo = CurrentLeftWingLocation - LastLeftWingLocation;
		const float LeftWingSpeed = LeftWingVelo.Size() / DeltaSeconds;

		const FVector RightWingVelo = CurrentRightWingLocation - LastRightWingLocation;
		const float RightWingSpeed = RightWingVelo.Size() / DeltaSeconds;

		CachedWingMovementSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_WING_MOVEMENT_SPEED), FVector2D(0.0, 1.0), Math::Max(LeftWingSpeed, RightWingSpeed));

		float HeadMovementSpeed = CurrentHeadRotation.Quaternion().AngularDistance(LastHeadRotation.Quaternion());
		CachedBodyMovementSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HEAD_MOVEMENT_SPEED), FVector2D(0.0, 1.0), HeadMovementSpeed);

		LastLeftWingLocation = CurrentLeftWingLocation;
		LastRightWingLocation = CurrentRightWingLocation;
		LastHeadRotation = CurrentHeadRotation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Head Movement"))
	float GetHeadMovement()
	{
		return CachedBodyMovementSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Wings Movement"))
	float GetWingsMovement()
	{
		return CachedWingMovementSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Relative Beak Rotation Alpha"))
	float GetRelativeBeakRotationAlpha()
	{
		// Very ugly way of checking for if the Beak is opened
		const FRotator BeakRelativeRotation = SkelMeshComp.GetSocketTransform(n"Beak", ERelativeTransformSpace::RTS_ParentBoneSpace).Rotator();
		return Math::IsNearlyEqual(BeakRelativeRotation.Pitch, -63, 0.1) ? 0.0 : 1.0;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is In Nest"))
	bool GetIsInNest()
	{
		if(CrackBird == nullptr)
			return false;

		return CrackBird.CurrentNest != nullptr;
	}

}