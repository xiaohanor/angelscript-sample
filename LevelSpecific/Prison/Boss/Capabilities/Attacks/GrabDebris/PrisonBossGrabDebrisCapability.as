class UPrisonBossGrabDebrisCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 159;

	APrisonBoss Boss;
	AHazePlayerCharacter TargetPlayer;

	TArray<APrisonBossMagneticDebris> NearbyDebris;
	APrisonBossMagneticDebris CurrentDebrisActor;

	float CurrentGrabTime = 0.0;
	float CurrentHoldTime = 0.0;

	bool bDowntimeActive = false;
	float CurrentDowntime = 0.0;
	float DowntimeDuration = 2.0;

	bool bLaunching = false;

	FVector GrabDebrisStartLocation;
	FVector GrabDebrisTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::GrabDebris)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::GrabDebris)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Zoe;

		Boss.SetDeflectStatus(true);

		Boss.AnimationData.bIsGrabbingDebris = true;
		Boss.AnimationData.bDebrisActive = true;

		TArray<APrisonBossMagneticDebris> AllDebris;
		AllDebris = TListedActors<APrisonBossMagneticDebris>().Array;
		for (APrisonBossMagneticDebris Debris : AllDebris)
		{
			if (Debris.GetDistanceTo(Boss) <= 20000.0)
			{
				NearbyDebris.Add(Debris);
			}
		}

		UPrisonBossEffectEventHandler::Trigger_GrabDebrisEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CurrentDebrisActor != nullptr)
			CurrentDebrisActor.Destroy();

		CurrentDebrisActor = nullptr;

		Boss.SetDeflectStatus(false);

		Boss.AnimationData.bDebrisActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Boss.RemoteHackingResponseComp.IsDisabledForPlayer(Game::Mio))
			return;

		if (HasControl())
		{
			if (bDowntimeActive)
			{
				CurrentDowntime += DeltaTime;
				if (CurrentDowntime >= DowntimeDuration)
					bDowntimeActive = false;
			}
			else if (CurrentDebrisActor == nullptr)
			{
				CurrentHoldTime = 0.0;
				CrumbGrabDebris(NearbyDebris[Math::RandRange(0, NearbyDebris.Num() - 1)]);
			}
		}

		if (CurrentDebrisActor != nullptr)
		{
			if (!bLaunching)
			{
				CurrentGrabTime += DeltaTime;
				float GrabAlpha = Math::Saturate(Boss.AttackDataComp.EaseInOutCurve.GetFloatValue(CurrentGrabTime/PrisonBoss::GrabDebrisGrabDuration));

				FVector Loc = Math::Lerp(GrabDebrisStartLocation, Boss.Mesh.GetSocketLocation(n"Align"), GrabAlpha);
				FRotator TargetRot = (GrabDebrisStartLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();

				if (GrabAlpha >= 1.0)
				{
					Loc = Math::VInterpTo(CurrentDebrisActor.ActorLocation, Boss.Mesh.GetSocketLocation(n"Align"), DeltaTime, 5.0);
					
					TargetRot = (TargetPlayer.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
				}

				FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRot, DeltaTime, 2.0);
				Boss.SetActorRotation(Rot);

				CurrentDebrisActor.SetActorLocation(Loc);

				CurrentDebrisActor.AddActorLocalRotation(FRotator(45.0 * DeltaTime, 90.0 * DeltaTime, 180.0 * DeltaTime));

				if (CurrentGrabTime >= PrisonBoss::GrabDebrisGrabDuration)
				{
					if (HasControl())
					{
						CurrentHoldTime += DeltaTime;
						if (CurrentHoldTime >= PrisonBoss::GrabDebrisHoldDuration)
						{
							FVector DebrisTargetLoc = TargetPlayer.ActorCenterLocation;
							FVector DebrisDir = (DebrisTargetLoc - CurrentDebrisActor.ActorLocation).GetSafeNormal();

							CrumbReleaseDebris(CurrentDebrisActor.ActorLocation, DebrisDir);
						}
					}
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbGrabDebris(APrisonBossMagneticDebris Debris)
	{
		CurrentGrabTime = 0.0;
		CurrentHoldTime = 0.0;
		CurrentDebrisActor = Debris;

		GrabDebrisStartLocation = CurrentDebrisActor.ActorLocation;
		FVector DirToDebris = (CurrentDebrisActor.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		GrabDebrisTargetLocation = Boss.ActorLocation + (DirToDebris * -100.0) + (DirToDebris.RotateAngleAxis(-90.0, FVector::UpVector) * -35.0) + (Boss.ActorUpVector * 575.0);

		bLaunching = false;

		Boss.AnimationData.bIsLaunchingDebris = false;
		Boss.AnimationData.bIsGrabbingDebris = true;

		UPrisonBossEffectEventHandler::Trigger_GrabDebrisPull(Boss);
		UPrisonBossMagneticDebrisEffectEventHandler::Trigger_GrabbedByBoss(Debris);
	}

	UFUNCTION(CrumbFunction)
	void CrumbReleaseDebris(FVector Location, FVector Dir)
	{
		CurrentDebrisActor.Launch(Location, Dir, true);

		if (!Game::Zoe.HasControl() && HasControl())
			CurrentDebrisActor.SlowdownLaunchForNetworkCatchup();

		CurrentDebrisActor.OnExploded.AddUFunction(this, n"DebrisExploded");

		bLaunching = true;

		Boss.AnimationData.bIsGrabbingDebris = false;
		Boss.AnimationData.bIsLaunchingDebris = true;

		UPrisonBossEffectEventHandler::Trigger_GrabDebrisThrow(Boss);
	}

	UFUNCTION()
	private void DebrisExploded(APrisonBossMagneticDebris Debris, bool bHitBoss)
	{
		CurrentDowntime = 0.0;
		bDowntimeActive = true;
		CurrentDebrisActor = nullptr;

		Boss.AnimationData.bDebrisActive = false;
	}
}