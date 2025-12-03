
UCLASS(Abstract)
class UCharacter_Enemy_Island_Shieldotron_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter LeftFootEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter RightFootEmitter;

	UPROPERTY(EditDefaultsOnly)
	float AttenuationScaling = 8000;

	FVector GetLeftArmLocation() const property
	{
		return Shieldotron.Mesh.GetSocketLocation(n"LeftHand");
	}

	FVector GetRightArmLocation() const property
	{
		return Shieldotron.Mesh.GetSocketLocation(n"RightHand");
	}

	FVector TrackedLeftArmLocation;
	FVector TrackedRightArmLocation;
	float TrackedLeftHandSpeed = 0.0;
	float TrackedRightHandSpeed = 0.0;

	const float MAX_TRACKED_ARM_SPEED = 600;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	ABasicAIGroundMovementCharacter Shieldotron;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Shieldotron = Cast<ABasicAIGroundMovementCharacter>(HazeOwner);
		LeftFootEmitter.AttachEmitterTo(Shieldotron.Mesh, n"LeftToeBase");
		RightFootEmitter.AttachEmitterTo(Shieldotron.Mesh, n"RightToeBase");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector LeftArmVelo = (LeftArmLocation - TrackedLeftArmLocation);
		TrackedLeftHandSpeed = (LeftArmVelo.Size() / DeltaSeconds) / MAX_TRACKED_ARM_SPEED;

		const FVector RightArmVelo = (RightArmLocation - TrackedRightArmLocation);
		TrackedRightHandSpeed = (RightArmVelo.Size() / DeltaSeconds) / MAX_TRACKED_ARM_SPEED;

		TrackedLeftArmLocation = LeftArmLocation;
		TrackedRightArmLocation = RightArmLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Sidescroller"))
	bool IsSidescroller()
	{
		AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();
		if(FullscreenPlayer != nullptr)
			return FullscreenPlayer.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller;

		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Combined Arm Movement Normalized"))
	float GetCombinedArmMovementNormalized()
	{
		return Math::Saturate((TrackedLeftHandSpeed + TrackedRightHandSpeed) / 2);
	}
}