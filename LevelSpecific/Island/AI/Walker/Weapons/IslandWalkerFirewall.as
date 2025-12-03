event void FIslandWalkerFirewallPreparedSignature(UIslandWalkerFlameThrowerComponent GasOrifice);

class AIslandWalkerFirewall : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	FIslandWalkerFirewallPreparedSignature OnPrepared;

	UIslandWalkerFlameThrowerComponent Flamethrower;
	AIslandWalkerArenaLimits Arena = nullptr;
	UIslandWalkerSettings Settings;
	TArray<FVector> Line;
	TArray<float> IgnitionTimes;
	FVector LineDir;

	bool bSprayingFire = false;
	bool bSpawningFires = false;
	float IgnitionStartTime;
	bool bDissipating = false;
	float DamagePerSecond = 1.0;
	float DissipateTime = BIG_NUMBER;
	float ExpirationTime = BIG_NUMBER;
	float ExtraOffset = 0.0;
	float BurnDuration = BIG_NUMBER;
	float ShenanigansHeight = 0.0;

	FHazeAcceleratedVector LineHead;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AIslandWalkerArenaLimits> Arenas;
		if (ensure(Arenas.Num() > 0))
			Arena = Arenas[0];
	}

	void StartSprayingFire(AHazeActor Owner, UIslandWalkerFlameThrowerComponent FlameThrowerComp, float DamagePerSec, float BurnTime, float _ShenanigansHeight)
	{
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		Flamethrower = FlameThrowerComp;
		ActorLocation = TargetLocation;
		bSprayingFire = true;
		IgnitionStartTime = Time::GameTimeSeconds;
		bSpawningFires = false;
		bDissipating = false;
		DissipateTime = BIG_NUMBER;
		ExpirationTime = BIG_NUMBER;
		Line.Reset();
		IgnitionTimes.Reset();
		DamagePerSecond = DamagePerSec;
		BurnDuration = BurnTime;
		ShenanigansHeight = _ShenanigansHeight;
		LineDir = FVector::ZeroVector;
		LineHead.SnapTo(TargetLocation);

		OnPrepared.Broadcast(Flamethrower);
	}

	void StopSprayingFire(float DissipateDelay)
	{
		if (bSprayingFire)		
			UIslandWalkerFirewallEventHandler::Trigger_OnStopSpawningFire(this);
		bSprayingFire = false;
		bSpawningFires = false;
		DissipateTime = Time::GameTimeSeconds + DissipateDelay;
		ExpirationTime = DissipateTime + Settings.FirewallPostDissipateRemainDuration;

		if ((Line.Num() > 0) && ActorLocation.IsWithinDist(Line.Last(), 20.0))
		{
			// Move line end a short distance 
			Line.Last() = ActorLocation;
		}
		else
		{
			// Place new line point at end
			Line.Add(ActorLocation);
			IgnitionTimes.Add(BIG_NUMBER);
		}
	}

	FVector GetTargetLocation() const property
	{
		FVector TargetLoc = Flamethrower.TargetLocation;
		if (ExtraOffset > SMALL_NUMBER)		
			TargetLoc += Flamethrower.SpreadDirection * ExtraOffset;
		if (Arena == nullptr)
			return TargetLoc;
		if (Arena.bIsFlooded)
			return Arena.GetAtFloodedPoolDepth(TargetLoc, 0.0);
		return Arena.GetFloorLocation(TargetLoc);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurTime = Time::GameTimeSeconds;
		if (CurTime > ExpirationTime)
		{
			ProjectileComp.Expire();
			return;
		}

		if (!bDissipating && (CurTime > DissipateTime))
		{
			// Fire is now harmless and will dissipate
			bDissipating = true;
			UIslandWalkerFirewallEventHandler::Trigger_OnFireBecomesHarmless(this);
		}
		if (bDissipating)
			return;

		if (bSprayingFire)
		{
			float SprayRange = (CurTime - IgnitionStartTime) * Settings.FirewallSprayFuelSpeed;
			if (!bSpawningFires && (SprayRange > Flamethrower.SprayDistance + ExtraOffset * 0.25))
			{
				// Start lighting fires
				bSpawningFires = true;
				UIslandWalkerFirewallEventHandler::Trigger_OnStartSpawningFire(this); 
				Line.Add(LineHead.Value);
				IgnitionTimes.Add(Time::GetGameTimeSince(IgnitionStartTime));
			}
		}	

		if (bSpawningFires)
		{
			// Spray has impacted, keep up with target location
			LineHead.AccelerateTo(TargetLocation, 0.2, DeltaTime);
			ActorLocation = LineHead.Value; 
			if (ShouldUpdateLineEnd(LineHead.Value))
			{
				LineDir = (LineHead.Value - Line.Last()).GetSafeNormal();
				Line.Add(LineHead.Value);
				IgnitionTimes.Add(Time::GetGameTimeSince(IgnitionStartTime));
			}
		}	

		// Check for damage
		for (AHazePlayerCharacter Target : Game::Players)
		{
			if (IsAffectedByFire(Target))
			{
				Target.DealTypedDamageBatchedOverTime(Flamethrower.Owner, DamagePerSecond * DeltaTime, EDamageEffectType::FireSoft, EDeathEffectType::FireSoft);
				Target.ApplyAdditiveHitReaction(Flamethrower.SprayDirection);
				UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(Target);
			}
		}

		UpdateLineBurning(LineHead.Value);

		float FFFrequency = 75.0;
		float FFIntensity = 0.3;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, LineHead.Value, 1500, 1000);

		DebugDraw();
	}

	bool ShouldUpdateLineEnd(FVector CurLoc)
	{
		// Note that this should not be called when line is empty
		FVector LineEnd = Line.Last();
		if (CurLoc.IsWithinDist(LineEnd, 80.0))
			return false;
		FVector LineProjectedLoc = LineEnd + LineDir * LineDir.DotProduct(LineHead.Value - LineEnd);
		if (CurLoc.IsWithinDist(LineProjectedLoc, 40.0))
			return false;
		return true;		
	}

	void UpdateLineBurning(FVector CurLoc)
	{
		float IgnitionAge = Time::GetGameTimeSince(IgnitionStartTime);
		if (IgnitionAge < BurnDuration)
			return;
		if (IgnitionTimes.Num() == 0)
			return;

		// Check if first point should burn out or be moved towards the front of the line
		float SegmentAge = IgnitionAge - IgnitionTimes[0];
		if (SegmentAge > BurnDuration)
		{
			if ((IgnitionTimes.Num() == 1) || (IgnitionAge - IgnitionTimes[1] > BurnDuration))
			{
				// Next point is also too old, snuff this one out (but keep the last one if we're still spawning fires)
				if (!bSpawningFires || IgnitionTimes.Num() > 1)
				{
					Line.RemoveAt(0);
					IgnitionTimes.RemoveAt(0);
					return;
				}
			}

			// Shrink line here	
			FVector NextLoc = (Line.Num() == 1) ? CurLoc : Line[1];
			float NextTime = (Line.Num() == 1) ? IgnitionAge : IgnitionTimes[1];
			float SegmentTimeSpan = NextTime - IgnitionTimes[0];
			float ShrinkFraction = (SegmentAge - BurnDuration) / SegmentTimeSpan;
			Line[0] = Math::Lerp(Line[0], NextLoc, ShrinkFraction);
			IgnitionTimes[0] = IgnitionAge - BurnDuration;
		}
	}

	bool IsAffectedByFire(AHazePlayerCharacter Player)
	{
		FVector PlayerLoc = Player.ActorCenterLocation;
		FVector ProjectedLoc;
		float Dummy;

		if (Flamethrower.IsImmuneDueToShenanigans(Player, Arena.Height + ShenanigansHeight))
			return false;

		if (bSprayingFire)
		{
			// Are being hit by flame itself?
			Math::ProjectPositionOnLineSegment(Flamethrower.LaunchLocation, ActorLocation, PlayerLoc, ProjectedLoc, Dummy); 
			if (PlayerLoc.Z > ProjectedLoc.Z)
				ProjectedLoc.Z = Math::Min(PlayerLoc.Z, ProjectedLoc.Z + Settings.FirewallDamageRadius * 0.5); // Fire reaches higher than radius
			if (PlayerLoc.IsWithinDist(ProjectedLoc, Settings.FirewallIgnitionFlameDamageRadius)) 
				return true;
		}

		// Check if target is within ignited line
		FVector CurLoc = ActorLocation;
		for (int i = Line.Num() - 1; i >= 0; i--)
		{
			Math::ProjectPositionOnLineSegment(CurLoc, Line[i], PlayerLoc, ProjectedLoc, Dummy);
			if (PlayerLoc.IsWithinDist2D(ProjectedLoc, Settings.FirewallDamageRadius))
			{
				if (PlayerLoc.Z < ProjectedLoc.Z + Settings.FirewallDamageRadius)				
					return true;
			}
			CurLoc = Line[i];
		}
		return false;
	}

	FVector GetFireSpreadDirection() const
	{
		return LineDir;		
	}

	// Get an array of evenly distributed locations along the ignited line (for audio)
	UFUNCTION(BlueprintPure)
	void GetFireSpread(TArray<FVector>&out OutLocations, float Interval = 300.0)
	{
		if (Line.Num() == 0)
			return;
		if (bDissipating)
			return;

		// Fire spread from the line head to first ignited index in line
		// and continues to the end of line
		FVector PrevLoc = LineHead.Value;
		OutLocations.Add(PrevLoc);
		float RemainingDist = Interval;
		for (int iLine = Line.Num() - 1; iLine >= 0; iLine--)
		{
			FVector LineLoc = Line[iLine];
			float Dist = LineLoc.Distance(PrevLoc);
			if (Dist < RemainingDist)
			{
				// Too close to add a point, continue checking along line
				RemainingDist -= Dist;
			}
			else
			{
				FVector ToLine = LineLoc - PrevLoc;
				float FirstFraction = (RemainingDist / Dist);
				OutLocations.Add(PrevLoc + ToLine * FirstFraction);
				int NumIntervals = Math::TruncToInt((Dist - RemainingDist) / Interval);
				for (int i = 0; i < NumIntervals; i++)
				{
					OutLocations.Add(PrevLoc + ToLine * (FirstFraction + ((Interval * (i+1)) / Dist)));
				}
				RemainingDist = Interval - (Dist - NumIntervals * Interval - RemainingDist);
			}
			PrevLoc = LineLoc;
		}

		// Move last location to line start or add a location there
		if (Line[0].IsWithinDist(OutLocations.Last(), Interval * 0.5))
			OutLocations.Last() = Line[0];
		else
			OutLocations.Add(Line[0]);
	}

	void DebugDraw()
	{
#if EDITOR
		WalkerFirewallDevToggles::DebugDrawFirewall.MakeVisible();
		if (WalkerFirewallDevToggles::DebugDrawFirewall.IsEnabled())
		{
			FVector Offset = FVector(0.0, 0.0, 10.0);
			Debug::DrawDebugLine(Flamethrower.LaunchLocation, ActorLocation, FLinearColor::DPink, 20.0); 

			FVector NextLoc = ActorLocation;
			for (int i = Line.Num() - 1; i >= 0; i--)
			{
				Debug::DrawDebugLine(Line[i] + Offset, NextLoc + Offset, FLinearColor::Purple, 10.0);
				NextLoc = Line[i];
			}
			Debug::DrawDebugSphere(TargetLocation + Offset, 50.0, 4, FLinearColor::Purple, 5.0);
			Debug::DrawDebugArrow(TargetLocation + Offset + FVector(0.0, 0.0, 50.0), TargetLocation + Offset + FVector(0.0, 0.0, 50.0) + GetFireSpreadDirection() * 100.0, 20.0, FLinearColor::Purple, 5.0);

			WalkerFirewallDevToggles::DebugDrawBurnTimes.MakeVisible();
			if (WalkerFirewallDevToggles::DebugDrawBurnTimes.IsEnabled())
			{
				float BurnTime = Time::GetGameTimeSince(IgnitionStartTime);
				for (int i = 0; i < Line.Num(); i++)
				{
					if (IgnitionTimes[i] < BIG_NUMBER)
						Debug::DrawDebugString(Line[i] + Offset, "" + (BurnTime - IgnitionTimes[i]), Scale = 2.0);
				}
				Debug::DrawDebugString(TargetLocation + Offset * 10.0, "Burntime: " + BurnTime, Scale = 2.0);
			}
		}
#endif
	}	
}

UCLASS(Abstract)
class UIslandWalkerFirewallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	TArray<UNiagaraComponent> FireFX;

	UPROPERTY()
	bool bSpawningFire = false;

	UPROPERTY()
	float FireInterval = 300.0;

	UPROPERTY(BlueprintReadOnly)
	UIslandWalkerFlameThrowerComponent FlameThrower;

	UPROPERTY(BlueprintReadOnly)
	AIslandWalkerFirewall Firewall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Firewall = Cast<AIslandWalkerFirewall>(Owner);
		Firewall.OnPrepared.AddUFunction(this, n"OnPrepared");
	}

	UFUNCTION()
	private void OnPrepared(UIslandWalkerFlameThrowerComponent _FlameThrower)
	{
		FlameThrower = _FlameThrower;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSpawningFire() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSpawningFire() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireBecomesHarmless() {}

	UFUNCTION(BlueprintPure)
	FVector GetCurrentTargetLocation() const
	{
		return Firewall.ActorLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetFireSpreadDirection() const
	{
		if (!ensure(Firewall != nullptr))
			return FVector::ZeroVector;
 		return Firewall.GetFireSpreadDirection();
	}

	UFUNCTION(BlueprintPure)
	bool ShouldSpawnNewFire() const
	{
		if (!bSpawningFire)
			return false;

		if (FireFX.Num() == 0)
			return true;

		// Wait until we've established a spread direction
		if (GetFireSpreadDirection().IsZero())
			return false;		

		if (FireFX.Last().WorldLocation.IsWithinDist(Firewall.ActorLocation, FireInterval))
			return false;
		return true;	
	}
	
	UFUNCTION(BlueprintPure)
	bool IsAcidFire() const
	{
		auto HeadComp = UIslandWalkerHeadComponent::Get(Firewall.ProjectileComp.Launcher);
		return HeadComp.State > EIslandWalkerHeadState::Deployed;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldDissipateFire(UNiagaraComponent Fire) const
	{
		if (Fire == nullptr)
			return true;

		if (Firewall.Line.Num() == 0)
			return false; // Line hasn't started yet

		if (Fire.WorldLocation.IsWithinDist2D(Firewall.Line[0], FireInterval * 0.5))
			return false; // Close to start of line, keep fire

		FVector LineStartDir = (Firewall.Line.Num() == 1) ? (Firewall.ActorLocation - Firewall.Line[0]) : (Firewall.Line[1] - Firewall.Line[0]);
		LineStartDir = LineStartDir.GetSafeNormal();
		if (LineStartDir.DotProduct(Fire.WorldLocation - Firewall.Line[0]) > 0.0)
			return false; // Ahead of last segment on line, keep fire

		return true;
	}
}

namespace WalkerFirewallDevToggles
{
	const FHazeDevToggleCategory FirewallCategory = FHazeDevToggleCategory(n"WalkerFireWall");
	const FHazeDevToggleBool DebugDrawFirewall = FHazeDevToggleBool(FirewallCategory, n"Debug draw firewall");
	const FHazeDevToggleBool DebugDrawBurnTimes = FHazeDevToggleBool(FirewallCategory, n"Debug draw burn times");
}


