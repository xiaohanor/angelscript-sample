class USummitRaftPaddleCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitRaftPaddle Paddle;
	USummitRaftPaddleComponent PaddleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PaddleComp = USummitRaftPaddleComponent::Get(Player);

		auto PaddleActor = SpawnActor(PaddleComp.PaddleClass);
		Paddle = Cast<ASummitRaftPaddle>(PaddleActor);
		Paddle.AttachToActor(Player, n"RightAttach", EAttachmentRule::SnapToTarget);
		Paddle.AddActorDisable(this);

		PaddleComp.Paddle = Paddle;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Paddle.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Line("Paddle", Paddle.Root.WorldLocation, Paddle.PaddleBottom.WorldLocation, 7, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Paddle.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Paddle.AddActorDisable(this);
	}
};