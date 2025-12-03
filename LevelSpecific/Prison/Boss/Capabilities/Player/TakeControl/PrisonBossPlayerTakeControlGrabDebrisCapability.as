class UPrisonBossPlayeTakeControlGrabDebrisCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 159;

	APrisonBoss BossActor;
	AHazePlayerCharacter Player;
	UPrisonBossPlayerTakeControlComponent TakeControlComp;

	TArray<APrisonBossMagneticDebris> NearbyDebris;
	APrisonBossMagneticDebris CurrentDebrisActor;
	APrisonBossMagneticDebris PreviousDebrisActor;

	bool bTutorialCompleted = false;

	float CurrentDebrisHoldTime = 0.0;
	float MinDebrisHoldTime = 1.0;

	bool bDebrisInitialized = false;

	bool bCameraControlBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossActor = Cast<APrisonBoss>(Owner);
		TakeControlComp = UPrisonBossPlayerTakeControlComponent::Get(BossActor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BossActor.bControlled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossActor.bControlled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Game::Mio;

		bTutorialCompleted = false;
		TakeControlComp.bDebrisLaunchActive = false;

		if (!bDebrisInitialized)
		{
			TArray<APrisonBossMagneticDebris> AllDebris;
			AllDebris = TListedActors<APrisonBossMagneticDebris>().Array;
			for (APrisonBossMagneticDebris Debris : AllDebris)
			{
				if (Debris.GetDistanceTo(BossActor) <= 20000.0)
				{
					NearbyDebris.Add(Debris);
				}
			}
			
			bDebrisInitialized = true;
		}

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		TutorialPrompt.Text = BossActor.GrabDebrisText;

		for (APrisonBossMagneticDebris Debris : NearbyDebris)
		{
			Outline::ApplyOutlineOnActor(Debris, Player, Debris.OutlineDataAsset, this, EInstigatePriority::High);
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Debris.RootComp, -FVector::UpVector * 600.0, 0.0);

			Debris.ClearAllDisables();

			Debris.SetTargetWidgetEnabled(true);
		}

		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::AcceleratedNormal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeByInstigator(this);

		Player.RemoveTutorialPromptByInstigator(this);

		if (CurrentDebrisActor != nullptr)
			CurrentDebrisActor.Destroy();

		CurrentDebrisActor = nullptr;

		BossActor.AnimationData.bHoldingDebris = false;

		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::AcceleratedNormal);

		for (APrisonBossMagneticDebris Debris : NearbyDebris)
		{
			Outline::ClearOutlineOnActor(Debris, Player, this);
			Debris.SetTargetWidgetEnabled(false);
		}

		UnblockCameraControl();

		TakeControlComp.bDebrisLaunchActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && !TakeControlComp.bDebrisLaunchActive)
		{
			APrisonBossMagneticDebris TargetDebris = nullptr;
			for (APrisonBossMagneticDebris Debris : NearbyDebris)
			{
				if (!Debris.IsActorDisabled() && !Debris.bLaunched && !Debris.bDeflectedByBoss)
				{
					FVector Dir = (Debris.ActorLocation - Player.ViewLocation).GetSafeNormal();
					float Dot = Dir.DotProduct(Player.ViewRotation.ForwardVector);
					if (Dot >= 0.97)
					{
						TargetDebris = Debris;
						break;
					}
				}
			}

			if (TargetDebris != nullptr)
				CrumbGrabDebris(TargetDebris);
		}

		if (CurrentDebrisActor != nullptr)
		{
			FVector TargetLoc = Player.ViewLocation + (Player.ViewRotation.ForwardVector * 250.0) + (Player.ViewRotation.RightVector * -100.0) + (Player.ViewRotation.UpVector * 20.0);
			FVector CurrentLoc  = Math::VInterpTo(CurrentDebrisActor.ActorLocation, TargetLoc, DeltaTime, 5.0);
			CurrentDebrisActor.SetActorLocation(CurrentLoc);

			CurrentDebrisActor.AddActorLocalRotation(FRotator(45.0 * DeltaTime, 90.0 * DeltaTime, 180.0 * DeltaTime));

			float Scale = Math::FInterpConstantTo(CurrentDebrisActor.ActorScale3D.X, 0.5, DeltaTime, 2.0);
			CurrentDebrisActor.SetActorScale3D(FVector(Scale));

			CurrentDebrisHoldTime += DeltaTime;
		}

		if (HasControl())
		{
			if (!IsActioning(ActionNames::PrimaryLevelAbility))
			{
				if (CurrentDebrisActor != nullptr)
				{
					if (CurrentDebrisHoldTime >= MinDebrisHoldTime)
					{
						ReleaseDebris();
						return;
					}
				}
			}

			if (CurrentDebrisHoldTime >= MinDebrisHoldTime)
				ShowReleaseTutorial();
		}

		for (APrisonBossMagneticDebris Debris : NearbyDebris)
		{
			if (Debris.bTargetWidgetEnabled)
			{
				FVector DirToPlayerCamera = (Game::Mio.ViewLocation - Debris.ActorLocation).GetSafeNormal();
				Debris.TargetWidgetComp.SetWorldRotation(DirToPlayerCamera.Rotation());
				Debris.TargetWidgetComp.SetWorldLocation(Debris.ActorLocation + (DirToPlayerCamera * 400.0));
				
			}
		}
	}

	void ShowReleaseTutorial()
	{
		if (bTutorialCompleted)
			return;
		
		bTutorialCompleted = true;
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = BossActor.ReleaseDebrisText;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, CurrentDebrisActor.RootComp, FVector(0.0, 0.0, 0.0), 200.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbGrabDebris(APrisonBossMagneticDebris Debris)
	{
		Player.RemoveTutorialPromptByInstigator(this);

		CurrentDebrisActor = Debris;
		Outline::ClearOutlineOnActor(CurrentDebrisActor, Player, this);
		Debris.SetTargetWidgetEnabled(false);

		if (PreviousDebrisActor != nullptr)
		{
			if (PreviousDebrisActor.IsActorDisabled())
			{
				PreviousDebrisActor.ClearAllDisables();
				PreviousDebrisActor.Respawn();
			}
			else
				PreviousDebrisActor.bOverrideDisable = true;
		}

		BossActor.AnimationData.bHoldingDebris = true;

		Player.PlayForceFeedback(BossActor.MediumForceFeedback, false, true, this);

		TakeControlComp.Widget.Grabbed();

		UPrisonBossEffectEventHandler::Trigger_TakeControlPull(BossActor);
		UPrisonBossMagneticDebrisEffectEventHandler::Trigger_GrabbedByPlayer(Debris);
	}

	void ReleaseDebris()
	{
		FVector TargetLoc = Player.ViewLocation + (Player.ViewRotation.ForwardVector * 5000.0);
		FVector Dir = (TargetLoc - CurrentDebrisActor.ActorLocation).GetSafeNormal();
		CrumbReleaseDebris(CurrentDebrisActor.ActorLocation, Dir);

		TakeControlComp.Widget.Released();

		UPrisonBossEffectEventHandler::Trigger_TakeControlThrow(BossActor);
	}

	UFUNCTION(CrumbFunction)
	void CrumbReleaseDebris(FVector Location, FVector Dir)
	{
		CurrentDebrisHoldTime = 0.0;

		Player.StopCameraShakeByInstigator(this);

		CurrentDebrisActor.Launch(Location, Dir, false);

		if (!Game::Zoe.HasControl() && HasControl())
			CurrentDebrisActor.SlowdownLaunchForNetworkCatchup();

		CurrentDebrisActor.OnExploded.AddUFunction(this, n"DebrisExploded");
		PreviousDebrisActor = CurrentDebrisActor;
		CurrentDebrisActor = nullptr;

		Player.RemoveTutorialPromptByInstigator(this);

		BossActor.AnimationData.bHoldingDebris = false;

		Player.PlayCameraShake(BossActor.LightCameraShake, this, 0.5);
		Player.PlayForceFeedback(BossActor.HeavyForceFeedback, false, true, this);

		TakeControlComp.bDebrisLaunchActive = true;

		if (!bCameraControlBlocked)
		{
			bCameraControlBlocked = true;
			Player.BlockCapabilities(CameraTags::CameraControl, this);
		}
	}

	UFUNCTION()
	private void DebrisExploded(APrisonBossMagneticDebris Debris, bool bHitBoss)
	{
		if (IsActive())
		{
			Outline::ApplyOutlineOnActor(Debris, Player, Debris.OutlineDataAsset, this, EInstigatePriority::High);
			Debris.SetTargetWidgetEnabled(true);
		}

		TakeControlComp.bDebrisLaunchActive = false;
		UnblockCameraControl();
	}

	void UnblockCameraControl()
	{
		if (!bCameraControlBlocked)
			return;

		bCameraControlBlocked = false;
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
	}
}