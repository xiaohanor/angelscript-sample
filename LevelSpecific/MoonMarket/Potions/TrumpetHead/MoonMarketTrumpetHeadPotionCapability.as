class UMoonMarketTrumpetHeadPotionCapability : UMoonMarketPlayerShapeshiftCapability
{
	UMoonMarketTrumpetHeadPotionComponent TrumpetHeadComp;

	AMoonMarketTrumpetHead TrumpetHead;
	float LastHonkTime = 0;

	int Uses;
	int MaxTutorialUses = 2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UMoonMarketPlayerShapeshiftCapability::Setup();
		TrumpetHeadComp = UMoonMarketTrumpetHeadPotionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnActivated();

		TrumpetHead = SpawnActor(TrumpetHeadComp.TrumpetHeadClass, Player.ActorLocation);
		ShapeshiftComp.Shapeshift(TrumpetHead);
		TrumpetHead.AttachToComponent(Player.Mesh, n"Head", EAttachmentRule::SnapToTarget);
		Player.Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
		CurrentShape = TrumpetHead;

		if (Uses < MaxTutorialUses)
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::PrimaryLevelAbility;
			Prompt.Text = NSLOCTEXT("MoonMarketTrumpetHead", "TrumpetHeadPrompt", "Toot");
			Player.ShowTutorialPrompt(Prompt, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();
		TrumpetHead.DestroyActor();
		Player.Mesh.UnHideBoneByName(n"Head");
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(WasActionStarted(ActionNames::PrimaryLevelAbility) && Time::GetGameTimeSince(LastHonkTime) >= TrumpetHeadComp.HonkCooldown)
		{
			CrumbAirPush();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbAirPush()
	{
		LastHonkTime = Time::GameTimeSeconds;
		TrumpetHead.SquashRoot.BounceScale = FVector(2.5, 0.7, 2.5);
		TrumpetHead.SquashRoot.SetBounce(0.1, 2000, 0.1);
		UMoonMarketTrumpetHeadEventHandler::Trigger_OnDoot(TrumpetHead);

		if(!HasControl())
			return;

		TArray<EObjectTypeQuery> HitChannels;
		HitChannels.Add(EObjectTypeQuery::Pawn);
		HitChannels.Add(EObjectTypeQuery::PlayerCharacter);
		FHazeTraceSettings CapsuleTrace = Trace::InitObjectTypes(HitChannels);

		CapsuleTrace.IgnoreActor(Player);
		CapsuleTrace.UseCapsuleShape(TrumpetHeadComp.AirPushRadius, TrumpetHeadComp.AirPushRadius * 2);

		// Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
		// FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
		// DebugSettings.Thickness = 5;
		// DebugSettings.TraceColor = FLinearColor::Purple;
		//CapsuleTrace.DebugDraw(DebugSettings);

		FVector TraceOrigin = TrumpetHead.ActorLocation + Player.ActorForwardVector * TrumpetHeadComp.AirPushRadius;
		FVector TraceEnd = TraceOrigin + Player.ActorForwardVector * TrumpetHeadComp.AirPushLength;
		FHitResultArray HitArray = CapsuleTrace.QueryTraceMulti(TraceOrigin, TraceEnd);

		for(auto Hit : HitArray)
		{
			if(Hit.bBlockingHit)
			{
				AHazeActor HitActor = Cast<AHazeActor>(Hit.Actor);
				if(HitActor == nullptr)
					continue;

				UMoonMarketTrumpetHonkResponseComponent ResponseComp = UMoonMarketTrumpetHonkResponseComponent::Get(HitActor);
				if(ResponseComp != nullptr)
					ResponseComp.OnHonkedAt.Broadcast(Player);

				UHazeMovementComponent Movecomp = UHazeMovementComponent::Get(HitActor);
				if(Movecomp == nullptr && HitActor.AttachParentActor != nullptr)
					Movecomp = UHazeMovementComponent::Get(HitActor.AttachParentActor);

				if(Movecomp != nullptr)
				{
					CrumbApplyImpulse(Movecomp, (Hit.ImpactPoint - TraceOrigin).GetSafeNormal());
				}
			}
		}

		float MaxDistance = 250.0;
		for (AHazePlayerCharacter WorldPlayer : Game::Players)
		{
			WorldPlayer.PlayWorldCameraShake(TrumpetHeadComp.CameraShake, this, Player.ActorLocation, MaxDistance / 2.0, MaxDistance);
			
			if (WorldPlayer == Player)
			{
				WorldPlayer.PlayForceFeedback(TrumpetHeadComp.FFTootTrigger, false, false, this);
			}
			else
			{
				float Dist = WorldPlayer.GetDistanceTo(Player);
				float Intensity = Math::Saturate(MaxDistance / Dist); 
				WorldPlayer.PlayForceFeedback(TrumpetHeadComp.FFToot, false, false, this, Intensity);
				Print(f"{Intensity=}");
			}
		}

		Uses++;

		if (Uses >= MaxTutorialUses)
			Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbApplyImpulse(UHazeMovementComponent Movecomp, FVector ImpulseDirection)
	{
		Movecomp.AddPendingImpulse(ImpulseDirection * TrumpetHeadComp.AirPushStrength + FVector::UpVector * 200);
	}
};