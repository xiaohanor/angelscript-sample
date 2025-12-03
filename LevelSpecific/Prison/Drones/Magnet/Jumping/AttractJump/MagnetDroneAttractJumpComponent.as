UCLASS(Abstract)
class UMagnetDroneAttractJumpComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FTutorialPrompt TutorialPrompt;

	private UMagnetDroneAttachedComponent AttachedComp;
	private UPlayerMovementComponent MoveComp;

	FMagnetDroneTargetData JumpAimData;
	uint StartJumpAttractFrame = 0;

	TArray<FInstigator> ShowTutorialPromptInstigators;
	TArray<FInstigator> FinishedTutorialInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneAttractJump");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		JumpAimData.LogToTemporalLog(TEMPORAL_LOG(this));
		TEMPORAL_LOG(this)
			.Value("StartJumpAttractFrame", StartJumpAttractFrame);
		;
#endif
	}

	FVector GetJumpDirection() const
	{
		if(AttachedComp.AttachedData.CanAttach())
		{
			if(AttachedComp.AttachedData.IsSocket())
				return AttachedComp.AttachedData.GetSocketComp().ForwardVector;
		}

		if(MoveComp.GroundContact.IsValidBlockingHit())
			return MoveComp.GroundContact.Normal;

		return MoveComp.WorldUp;
	}
};

namespace MagnetDrone
{
	/**
	 * Show the Attract Jump tutorial in the middle of the attract jump path (if one exists)
	 * This tutorial will be automatically cleared when performed.
	 */
	UFUNCTION(BlueprintCallable, Category = "Magnet Drone")
	void ShowAttractJumpTutorial(FInstigator Instigator)
	{
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Drone::MagnetDronePlayer);
		if(AttractJumpComp == nullptr)
			return;

		AttractJumpComp.ShowTutorialPromptInstigators.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Magnet Drone")
	void RemoveAttractJumpTutorial(FInstigator Instigator)
	{
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Drone::MagnetDronePlayer);
		if(AttractJumpComp == nullptr)
			return;

		AttractJumpComp.ShowTutorialPromptInstigators.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Magnet Drone")
	void FinishAttractJumpTutorial(FInstigator Instigator)
	{
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Drone::MagnetDronePlayer);
		if(AttractJumpComp == nullptr)
			return;

		AttractJumpComp.FinishedTutorialInstigators.AddUnique(Instigator);
	}

	/**
	 * Allow an attract jump tutorial to be displayed with this instigator again after having finished.
	 */
	UFUNCTION(BlueprintCallable, Category = "Magnet Drone")
	void ResetAttractJumpTutorial(FInstigator Instigator)
	{
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Drone::MagnetDronePlayer);
		if(AttractJumpComp == nullptr)
			return;

		AttractJumpComp.FinishedTutorialInstigators.RemoveSingleSwap(Instigator);
	}
}