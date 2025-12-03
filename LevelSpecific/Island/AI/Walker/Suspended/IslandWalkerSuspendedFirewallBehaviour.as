class UIslandWalkerSuspendedFirewallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandWalkerSettings Settings;
	UIslandWalkerFuelAndFlameThrowerComponent Flamethrower = nullptr;
	AIslandWalkerHead Head;
	UIslandWalkerComponent WalkerComp;
	AHazePlayerCharacter Target;
	bool bTracking;
	float TrackDuration;
	bool bSprayingFuel;
	bool bIgniting;
	FVector SweepStartLoc;
	FVector SweepIgnitionLoc;
	FVector LastImpactEffectLoc;
	FVector WalkerStartLoc;
	FVector WalkerIgnitionLoc;
	float PreviousYaw;

	float SprayFuelDuration = 4.0;

	TArray<AIslandWalkerFueledFirewall> FireWalls;
	
	TArray<AHazePlayerCharacter> ReprisalTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		UIslandWalkerNeckRoot::Get(Owner).OnHeadSetup.AddUFunction(this, n"OnSetupHead");
		TArray<UIslandWalkerCablesTargetRoot> Cables;
		Owner.GetComponentsByClass(Cables);
		for (UIslandWalkerCablesTargetRoot Cable : Cables)
		{
			Cable.OnCablesTargetSetup.AddUFunction(this, n"OnSetupCables");
		}
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
	}

	UFUNCTION()
	private void OnSetupHead(AIslandWalkerHead WalkerHead)
	{
		Head = WalkerHead;
		Flamethrower = WalkerHead.FuelAndFlameThrower;
	}

	UFUNCTION()
	private void OnSetupCables(AIslandWalkerCablesTarget Cable)
	{
		Cable.OnTakeDamage.AddUFunction(this, n"OnCableDamage");
	}

	UFUNCTION()
	private void OnCableDamage(AIslandWalkerCablesTarget Cable)
	{
		if (WalkerComp.ArenaLimits == nullptr)
			return;

		// We've taken damage, let's burn the culprits
		ReprisalTargets.SetNum(2);
		ReprisalTargets[0] = Cable.DestroyingPlayer.OtherPlayer;
		ReprisalTargets[1] = Cable.DestroyingPlayer;

		// Burn them as soon as possible!
		if (!IsActive())
		{
			TargetComp.SetTarget(ReprisalTargets[0]);	
			Cooldown.Set(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Flamethrower == nullptr)
			return false;		
		if (!TargetComp.HasValidTarget() && (ReprisalTargets.Num() == 0))
			return false;
		if (Time::GetGameTimeSince(WalkerComp.SuspendIntroCompleteTime) < 2.0)
		 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > TrackDuration + SprayFuelDuration + Settings.FirewallIgnitionPause + Settings.FirewallIgniteDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		bTracking = true;
		TrackDuration = 0.0;
		bSprayingFuel = false;
		bIgniting = false;
		LastImpactEffectLoc = FVector(BIG_NUMBER);
		FireWalls.Reset();
		WalkerComp.NumSuspendedSprayGasWithNoSpawn++;
		SprayFuelDuration = Settings.FirewallSprayFuelDuration;
		PreviousYaw = Owner.ActorRotation.Yaw;

		// Sweep along one edge of pool
		WalkerComp.ArenaLimits.GetInnerEdge(Target.ActorLocation, SweepStartLoc, SweepIgnitionLoc, Settings.FirewallOutsidePoolRange);
		if ((ReprisalTargets.Num() > 0) && (Target == ReprisalTargets[0]))
		{
			// Attack edge where target will land
			FVector ReprisalLoc = Target.IsMio() ? WalkerComp.ArenaLimits.ZoeLaunchArea.WorldLocation : WalkerComp.ArenaLimits.MioLaunchArea.WorldLocation;
			WalkerComp.ArenaLimits.GetInnerEdge(ReprisalLoc, SweepStartLoc, SweepIgnitionLoc, Settings.FirewallOutsidePoolRange);
			ReprisalTargets.RemoveAt(0);
			SprayFuelDuration *= 0.25;
		}
		SweepStartLoc.Z += Settings.FirewallDamageRadius * 0.25;
		SweepIgnitionLoc.Z += Settings.FirewallDamageRadius * 0.25;

		WalkerComp.ArenaLimits.GetInnerEdge((SweepStartLoc + SweepIgnitionLoc) * 0.5, WalkerStartLoc, WalkerIgnitionLoc, -Settings.FirewallWalkerDistanceFromPoolEdge);
		FVector Dir = (WalkerIgnitionLoc - WalkerStartLoc).GetSafeNormal();
		WalkerStartLoc -= Dir * Settings.FirewallWalkerDistanceFromPoolEdge * 0.1;
		WalkerIgnitionLoc += Dir * Settings.FirewallWalkerDistanceFromPoolEdge * 0.1;
		WalkerStartLoc.Z = WalkerComp.ArenaLimits.Height + Settings.SuspendHeight - 200.0;
		WalkerIgnitionLoc.Z = WalkerStartLoc.Z;
		if ((WalkerStartLoc - WalkerIgnitionLoc).DotProduct(SweepStartLoc - SweepIgnitionLoc) < 0.0)
		{
			FVector Swap = WalkerStartLoc;
			WalkerStartLoc = WalkerIgnitionLoc;
			WalkerIgnitionLoc = Swap;
		}

		Flamethrower.TargetLocation = SweepStartLoc;

		WalkerComp.ArenaLimits.DisableRespawnPointsAtSide((SweepStartLoc + SweepIgnitionLoc) * 0.5, this);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if ((ActiveDuration > SprayFuelDuration) && (ReprisalTargets.Num() == 0))
			Cooldown.Set(Settings.FirewallCooldown);	
		
		Owner.ClearSettingsByInstigator(this);

		// Switch target if possible
		if (ReprisalTargets.Num() > 0)
			TargetComp.SetTarget(ReprisalTargets[0]);
		else if (TargetComp.IsValidTarget(Target.OtherPlayer))
			TargetComp.SetTarget(Target.OtherPlayer);
		else
			TargetComp.SetTarget(nullptr);

		AnimComp.AimYaw.Clear(this);
		AnimComp.AimPitch.Clear(this);

		WalkerComp.ArenaLimits.EnableAllRespawnPoints(this);		

		for (AIslandWalkerFueledFirewall Firewall : FireWalls)
		{
			Firewall.StopIgniting(Settings.FirewallDissipateDuration);
		}

		if (bSprayingFuel)
			UIslandWalkerHeadEffectHandler::Trigger_OnFirewallSprayFuelStop(Head);
		if (bIgniting)
			UIslandWalkerHeadEffectHandler::Trigger_OnFirewallIgnitionStop(Head);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeSinceTracking = (ActiveDuration - TrackDuration);
		if (bTracking)
		{
			TrackDuration = ActiveDuration;
			FVector SweepCenter = (SweepStartLoc + SweepIgnitionLoc) * 0.5;
			DestinationComp.RotateTowards(SweepCenter);
			FVector WalkerLoc = (WalkerStartLoc + WalkerIgnitionLoc) * 0.5;
			DestinationComp.MoveTowardsIgnorePathfinding(WalkerLoc, Settings.SuspendAcceleration);


			// Rotate ahead towards sweep center, but not too far from actor forward since cables should never slide in opposite direction from walker turn
			FVector FocusLoc = SweepCenter;
			if (Owner.ActorForwardVector.DotProduct(SweepCenter - WalkerLoc) < 0.0)
				FocusLoc = SweepCenter + Owner.ActorForwardVector.RotateAngleAxis(Math::Sign(FRotator::NormalizeAxis(Owner.ActorRotation.Yaw - PreviousYaw)) * 60.0, FVector::UpVector) * 4000.0;
			WalkerComp.MoveCables(WalkerLoc, FocusLoc, 2.0);

			if (Owner.ActorForwardVector.DotProduct((SweepCenter - Owner.ActorLocation).GetSafeNormal2D()) > 0.866)
			{
				bTracking = false;
				
				// All turning after this should be responsive, we will move rotation target smoothly instead
				UIslandWalkerSettings::SetSuspendedTurnDuration(Owner, 1.0, this, EHazeSettingsPriority::Gameplay);

				UIslandWalkerHeadEffectHandler::Trigger_OnFirewallSprayFuelTelegraph(Head, FIslandWalkerSprayFireParams(Flamethrower));
			}
		}
		else if (ActiveDuration < TrackDuration + SprayFuelDuration)
		{
			float PreSprayDuration = (SprayFuelDuration * 0.25);
			if (!bSprayingFuel)
			{
				// Check if we should start spraying next tick
				if ((TimeSinceTracking > PreSprayDuration) && HasControl())
					CrumbStartSprayingFuel(SweepStartLoc, SweepIgnitionLoc);

				// Rotate towards where we will start spraying
				float Alpha = Math::Clamp(TimeSinceTracking / PreSprayDuration, 0.0, 1.0);
				FVector SweepCenter = (SweepStartLoc + SweepIgnitionLoc) * 0.5;
				DestinationComp.RotateTowards(Math::Lerp(SweepCenter, SweepStartLoc, Alpha));

				// Move us and cables towards that edge of pool
				DestinationComp.MoveTowardsIgnorePathfinding(WalkerStartLoc, Settings.SuspendAcceleration * 1.4);
				WalkerComp.MoveCables(WalkerStartLoc, SweepStartLoc, PreSprayDuration * 0.5);
			}
			else
			{
				// We're spraying fuel all over this side of pool
				float SprayDuration = (SprayFuelDuration - PreSprayDuration);
				float Alpha = (TimeSinceTracking - PreSprayDuration) / SprayDuration; 
				Flamethrower.TargetLocation = Math::Lerp(SweepStartLoc, SweepIgnitionLoc, Alpha);

				// Rotate towards position slightly ahead of target location so turning can keep up and spray has time to reach there
				DestinationComp.RotateTowards(Math::Lerp(SweepStartLoc, SweepIgnitionLoc, Math::Min(Alpha * 1.2, 1.0))); 
				DestinationComp.MoveTowardsIgnorePathfinding(WalkerIgnitionLoc, Settings.SuspendAcceleration * 1.4);
				WalkerComp.MoveCables(WalkerIgnitionLoc, Math::Lerp(SweepStartLoc, SweepIgnitionLoc, Math::Min(Alpha * 5.0, 1.0)), SprayDuration * 0.5);
			}
		}
		else if (ActiveDuration < TrackDuration + SprayFuelDuration + Settings.FirewallIgnitionPause)
		{
			if (bSprayingFuel)
			{
				bSprayingFuel = false;
				for (int i = 0; i < FireWalls.Num(); i++)
				{
					FireWalls[i].StopSprayingFuel();
				}
				AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Medium, this);

				UIslandWalkerHeadEffectHandler::Trigger_OnFirewallSprayFuelStop(Head);
			}
			
			Flamethrower.TargetLocation = SweepIgnitionLoc;
			DestinationComp.RotateTowards(SweepIgnitionLoc);
			DestinationComp.MoveTowardsIgnorePathfinding(WalkerIgnitionLoc, 400.0);
			WalkerComp.MoveCables(WalkerIgnitionLoc, Flamethrower.TargetLocation, 10.0);
		}
		else
		{
			if (!bIgniting)
			{
				// Let it burn!
				bIgniting = true;
				AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::SprayGas, EBasicBehaviourPriority::Medium, this);
				for (int i = 0; i < FireWalls.Num(); i++)
				{
					FireWalls[i].StartIgniting(Settings.FirewallDamagePerSecond, Settings.FirewallBurnDuration);
				}
				UIslandWalkerHeadEffectHandler::Trigger_OnFirewallIgnitionStart(Head, FIslandWalkerSprayFireParams(Flamethrower));
			}

			float TimeSinceIgnition = TimeSinceTracking - SprayFuelDuration - Settings.FirewallIgnitionPause;
			float Alpha = TimeSinceIgnition / Settings.FirewallIgniteDuration; 
			Flamethrower.TargetLocation = Math::Lerp(SweepIgnitionLoc, SweepStartLoc, Alpha);

			// Rotate towards position slightly ahead of target location so turning can keep up and ignition flame has time to reach there
			DestinationComp.RotateTowards(Math::Lerp(SweepIgnitionLoc, SweepStartLoc, Math::Min(Alpha * 1.2, 1.0))); 
			DestinationComp.MoveTowardsIgnorePathfinding(WalkerStartLoc, Settings.SuspendAcceleration);
			WalkerComp.MoveCables(WalkerStartLoc, SweepStartLoc, Settings.FirewallIgniteDuration);
		}

		AnimComp.AimYaw.Apply(0.0, this, EInstigatePriority::Normal);
		AnimComp.AimPitch.Apply(-15.0, this, EInstigatePriority::Normal);

		PreviousYaw = Owner.ActorRotation.Yaw;

		if(bSprayingFuel || bIgniting)
		{
			float FFFrequency = bIgniting ? 150.0 : 75;
			float FFIntensity = bIgniting ? 0.3 : 0.5;
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
			FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, Flamethrower.TargetLocation, 1500, 1000);
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(SweepStartLoc, SweepStartLoc + FVector(0,0,500), FLinearColor::Green, 5.0);
			Debug::DrawDebugLine(SweepIgnitionLoc, SweepIgnitionLoc + FVector(0,0,500), FLinearColor::Red, 5.0);
			Debug::DrawDebugLine(SweepStartLoc, SweepIgnitionLoc, FLinearColor::LucBlue, 2.0);
			if (bSprayingFuel)
				Debug::DrawDebugLine(Flamethrower.LaunchLocation, Flamethrower.TargetLocation, FLinearColor::Yellow);
			if (bIgniting)
				Debug::DrawDebugLine(Flamethrower.LaunchLocation, Flamethrower.TargetLocation, FLinearColor::Red);
		}
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartSprayingFuel(FVector StartLoc, FVector IgnitionLoc)
	{
		bSprayingFuel = true;
		SweepStartLoc = StartLoc;
		SweepIgnitionLoc = IgnitionLoc;
		Flamethrower.TargetLocation = SweepStartLoc;

		AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::SprayGas, EBasicBehaviourPriority::Medium, this);

		UIslandWalkerHeadEffectHandler::Trigger_OnFirewallSprayFuelStart(Head, FIslandWalkerSprayFireParams(Flamethrower));

		FireWalls.SetNum(3);
		for (int i = 0; i < FireWalls.Num(); i++)
		{
			FireWalls[i] = Cast<AIslandWalkerFueledFirewall>(Flamethrower.Launch(Flamethrower.SprayDirection * Settings.FirewallSprayFuelSpeed).Owner);
			FireWalls[i].ExtraOffset = i * Settings.FirewallDamageRadius * 1.2;
			FireWalls[i].StartSprayingFuel(Owner, Flamethrower);
		}
	}
}
