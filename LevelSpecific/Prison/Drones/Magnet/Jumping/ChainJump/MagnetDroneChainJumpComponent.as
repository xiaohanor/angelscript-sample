namespace MagnetDroneTags
{
	const FName BlockedWhileChainJumping = n"BlockedWhileChainJumping";
}

UCLASS(NotBlueprintable)
class UMagnetDroneChainJumpComponent : UActorComponent
{
	private UMagnetDroneJumpComponent JumpComp;

	private AHazePlayerCharacter Player;
	private FInstigator CurrentChainJumpInstigator;
	private uint StopChainJumpingFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneChainJump");
#endif
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("CurrentChainJumpInstigator", CurrentChainJumpInstigator);
		TemporalLog.Value("StopChainJumpingFrame", StopChainJumpingFrame);
	}
	#endif

	void ApplyChainJump(FInstigator Instigator)
	{
		if(!ensure(!CurrentChainJumpInstigator.IsValid()))
			return;

		if(!ensure(Instigator.IsValid()))
			return;

		CurrentChainJumpInstigator = Instigator;
		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileChainJumping, this);
	}

	void ClearChainJump(FInstigator Instigator)
	{
		if(!ensure(CurrentChainJumpInstigator.IsValid()))
			return;

		if(!ensure(CurrentChainJumpInstigator == Instigator))
			return;

		CurrentChainJumpInstigator = nullptr;

		StopChainJumpingFrame = Time::FrameNumber;
		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileChainJumping, this);
	}

	bool IsChainJumping() const
	{
		return CurrentChainJumpInstigator.IsValid();
	}

	bool WasChainJumpingThisFrame() const
	{
		if(IsChainJumping())
			return true;

		if(StopChainJumpingFrame == Time::FrameNumber)
			return true;

		return false;
	}
};