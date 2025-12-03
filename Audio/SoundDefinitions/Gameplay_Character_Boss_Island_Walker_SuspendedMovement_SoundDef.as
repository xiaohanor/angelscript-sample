
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_SuspendedMovement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AAIIslandWalker Walker;
	FVector PreviousForward;

	UPROPERTY(BlueprintReadOnly)
	float AngularVelocitySpeed = 0.0;

	TArray<UIslandWalkerCablesTargetRoot> CableTargetsRoots;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Walker = Cast<AAIIslandWalker>(HazeOwner);
		Walker.GetComponentsByClass(CableTargetsRoots);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Walker.WalkerComp.bSuspended;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Walker.WalkerComp.bSuspended)
			return true;

		for (UIslandWalkerCablesTargetRoot Root : CableTargetsRoots)
		{
			if ((Root.Target == nullptr) || !Root.Target.bCablesTargetDestroyed)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector CurrentForward = Walker.GetHead().ActorForwardVector;
		CurrentForward = CurrentForward.ConstrainToPlane(FVector::UpVector);
		CurrentForward.Normalize();

		AngularVelocitySpeed = Math::Clamp((CurrentForward - PreviousForward).Size() * 100, 0.0, 1.0);
		PreviousForward = CurrentForward;
	}

}