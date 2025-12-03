class UCoastBossDebugTimerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	ACoastBossActorReferences References;

	float Timer = 0.0;
	ACoastBoss CoastBoss;

	FHazeAcceleratedFloat AccScale;
	bool bWasDead = false;
	float Hue = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
		CoastBossDevToggles::Draw::DrawDebugTimer.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CoastBoss.State == ECoastBossState::Idle)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccScale.SnapTo(2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;
		
		if (!CoastBoss.bDead && CoastBoss.bStarted)
			Timer += DeltaTime;
		
		if (CoastBoss.bDead && !bWasDead)
			bWasDead = true;

		if (!CoastBossDevToggles::Draw::DrawDebugTimer.IsEnabled())
			return;

		FVector TextLocation = References.CoastBossPlane2D.ActorLocation + References.CoastBossPlane2D.ActorUpVector * References.CoastBossPlane2D.PlaneExtents.Y * 0.9;
		if (!CoastBoss.bDead)
		{
			Debug::DrawDebugString(TextLocation, "TIME: " + GetTimeWithHundreds(), ColorDebug::Leaf, 0.0, AccScale.Value);
		}
		else
		{
			AccScale.SpringTo(5.0, 50.0, 0.7, DeltaTime);
			float Scale = Math::Clamp(AccScale.Value, 0.1, 50.0);
			Hue += 255.0 * 0.33 * DeltaTime;
			Hue = Math::Wrap(Hue, 0.0, 255.95);
			uint8 IntHue = uint8(Hue);
			Debug::DrawDebugString(TextLocation, "TIME: " + GetTimeWithHundreds(), FLinearColor::MakeFromHSV8(IntHue, 255, 255), 0.0, Scale);
		}
	}

	float GetTimeWithHundreds()
	{
		return float(Math::FloorToInt(Timer * 10.0)) * 0.1;
	}

	bool TryCacheThings()
	{
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
				References = Refs.Single;
		}
		return References != nullptr;
	}
};