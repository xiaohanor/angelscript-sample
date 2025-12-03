
class USkylineBallBossDebugPrintCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	USkylineBallBossActionsComponent BossComp;
	ASkylineBallBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SkylineBallBossDevToggles::DebugPrintData.IsEnabled())
			return true;
		if (Boss.bDebugging)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SkylineBallBossDevToggles::DebugPrintData.IsEnabled())
			return false;
		if (Boss.bDebugging)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DebugPrint();
		if (BossComp.PositionActionQueue.Num() == 0 && Boss.bDebuggingMovement)
			DebugMove();
	}

	void DebugPrint()
	{
		FString DebugString = "";
		if (Boss.FreezeLocationRequesters.Num() > 0)
			DebugString += "Frozen Location\n";
		if (Boss.FreezeRotationRequesters.Num() > 0)
			DebugString += "Frozen Rotation\n";
		if (Boss.DisableAttacksRequesters.Num() > 0)
			DebugString += "Disabled Attacks\n";
		if (Boss.DisableAttacksRequesters.Num() == 0)
			DebugString += "Using Normal Phase Attacks for " + Boss.GetPhase();
		if (DebugString.Len() > 0)
			Debug::DrawDebugString(Boss.ActorLocation, DebugString, ColorDebug::Ruby);
	}

	void DebugMove()
	{
		TestMoveDash(ESkylineBallBossLocationNode::Laser1, 1.0);
		TestMoveIdle(1.5);
		TestMoveDash(ESkylineBallBossLocationNode::Laser2, 1.0);
		TestMoveIdle(0.5);
		TestMoveDash(ESkylineBallBossLocationNode::Laser3, 1.0);
	}

	private void TestMoveDash(ESkylineBallBossLocationNode Location, float Duration)
	{
		FSkylineBallBossPositionActionDashData Data;
		Data.DashTarget = Location;
		Data.Duration = Duration;
		BossComp.PositionActionQueue.Queue(Data);
	}
	
	private void TestMoveIdle(float Duration)
	{
		FSkylineBallBossPositionActionIdleData Data;
		Data.Duration = Duration;
		BossComp.PositionActionQueue.Queue(Data);
	}
}
