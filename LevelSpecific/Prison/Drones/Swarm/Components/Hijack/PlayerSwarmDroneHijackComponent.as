class UPlayerSwarmDroneHijackComponent : UActorComponent
{
	access CancelBlock = private, ApplySwarmHijackCancelBlock, ClearSwarmHijackCancelBlock;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> TargetableWidgetClass;

	UPROPERTY(Category = "Force Feedback")
	FVector2D SwarmificationTriggerRumbleRange = FVector2D(0.01, 0.2);

	UPROPERTY(Category = "Force Feedback")
	FHazeFrameForceFeedback DiveRumble;

	AHazePlayerCharacter PlayerOwner;

	access:CancelBlock TInstigated<bool> SwarmHijackCancelBlocks;
	default SwarmHijackCancelBlocks.SetDefaultValue(false);

	access SwarmDroneHijackCapability = private, USwarmDroneHijackCapability, USwarmDroneHijackExitCapability;
	access : SwarmDroneHijackCapability bool bHijackActive;
	access : SwarmDroneHijackCapability bool bHijackDiving;
	access : SwarmDroneHijackCapability bool bHijackExit;
	access : SwarmDroneHijackCapability USwarmDroneHijackTargetableComponent ForcedHijackableTargetComponent;

	USwarmDroneHijackTargetableComponent CurrentHijackTargetable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	void StartHijack(ASwarmDroneHijackable Hijackable)
	{
		FSwarmDroneHijackParams HijackParams;
		HijackParams.Player = PlayerOwner;
		Hijackable.HijackComponent.StartHijack(HijackParams);
	}

	void ApplySwarmHijackCancelBlock(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		SwarmHijackCancelBlocks.Apply(true, Instigator, Priority);
	}

	void ClearSwarmHijackCancelBlock(FInstigator Instigator)
	{
		SwarmHijackCancelBlocks.Clear(Instigator);
	}

    void ForceHijack(USwarmDroneHijackTargetableComponent HijackableTargetComponent)
    {
        ForcedHijackableTargetComponent = HijackableTargetComponent;
		CurrentHijackTargetable = HijackableTargetComponent;
    }

	bool IsSwarmHijackCancelBlocked() const
	{
		return SwarmHijackCancelBlocks.Get();
	}

	bool IsHijackActive() const
	{
		return bHijackActive;
	}

	bool IsHijackDiving() const
	{
		return bHijackDiving;
	}

	bool IsExitingHijack() const
	{
		return bHijackExit;
	}
}