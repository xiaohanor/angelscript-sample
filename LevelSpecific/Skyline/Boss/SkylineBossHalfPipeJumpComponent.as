UCLASS(NotBlueprintable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class USkylineBossHalfPipeJumpComponent : UActorComponent
{
	private ASkylineBoss SkylineBoss;
	private TSet<AGravityBikeFree> JumpingGravityBikes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SkylineBoss = Cast<ASkylineBoss>(Owner);

		SkylineBoss.LeftHalfPipeTrigger.OnHalfPipeJumpStarted.AddUFunction(this, n"OnHalfPipeJumpStarted");
		SkylineBoss.RightHalfPipeTrigger.OnHalfPipeJumpStarted.AddUFunction(this, n"OnHalfPipeJumpStarted");

		SkylineBoss.LeftHalfPipeTrigger.OnHalfPipeJumpEnded.AddUFunction(this, n"OnHalfPipeJumpEnded");
		SkylineBoss.RightHalfPipeTrigger.OnHalfPipeJumpEnded.AddUFunction(this, n"OnHalfPipeJumpEnded");
	}

	UFUNCTION(BlueprintPure)
	bool AreGravityBikesJumping() const
	{
		return JumpingGravityBikes.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerJumping(EHazePlayer InPlayer) const
	{
		if(!AreGravityBikesJumping())
			return false;

		const AHazePlayerCharacter Player = Game::GetPlayer(InPlayer);
		for(AGravityBikeFree GravityBike : JumpingGravityBikes)
		{
			if(GravityBike.GetDriver() != nullptr && GravityBike.GetDriver() == Player)
				return true;
		}

		return false;
	}

	UFUNCTION()
	private void OnHalfPipeJumpStarted(AGravityBikeFree GravityBike)
	{
		JumpingGravityBikes.Add(GravityBike);
	}

	UFUNCTION()
	private void OnHalfPipeJumpEnded(AGravityBikeFree GravityBike, bool bLanded)
	{
		JumpingGravityBikes.Remove(GravityBike);
	}
};