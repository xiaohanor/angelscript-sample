class AIslandWalkerFueledFirewall : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	FIslandWalkerFirewallPreparedSignature OnPrepared;

	UIslandWalkerFuelAndFlameThrowerComponent Flamethrower;
	AIslandWalkerArenaLimits Arena = nullptr;
	UIslandWalkerSettings Settings;
	TArray<FVector> Line;
	TArray<float> IgnitionTimes;
	FVector LineDir;
	int IgnitionIndex = 0;

	bool bSprayingFuel = false;
	bool bSpawningFuelPuddles = false;
	float SprayFuelStartTime;
	bool bIgnitionFlame = false;
	bool bIgnitedFuel = false;
	bool bStoppedIgniting = false;
	bool bDissipating = false;
	float IgnitionStartTime;
	float DamagePerSecond = 1.0;
	float DissipateTime = BIG_NUMBER;
	float ExpirationTime = BIG_NUMBER;
	float ExtraOffset = 0.0;
	float BurnDuration = BIG_NUMBER;

	FHazeAcceleratedVector LineHead;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AIslandWalkerArenaLimits> Arenas;
		if (ensure(Arenas.Num() > 0))
			Arena = Arenas[0];
	}

	void StartSprayingFuel(AHazeActor Owner, UIslandWalkerFuelAndFlameThrowerComponent FlameThrowerComp)
	{
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		Flamethrower = FlameThrowerComp;
		ActorLocation = TargetLocation;
		bSprayingFuel = true;
		SprayFuelStartTime = Time::GameTimeSeconds;
		IgnitionStartTime = BIG_NUMBER;
		bSpawningFuelPuddles = false;
		bIgnitionFlame = false;
		bIgnitedFuel = false;
		bStoppedIgniting = false;
		bDissipating = false;
		DissipateTime = BIG_NUMBER;
		ExpirationTime = BIG_NUMBER;
		Line.Reset();
		IgnitionTimes.Reset();
		LineDir = FVector::ZeroVector;
		LineHead.SnapTo(TargetLocation);

		OnPrepared.Broadcast(Flamethrower);
	}

	void StopSprayingFuel()
	{
		if (bSprayingFuel)		
			UIslandWalkerFueledFirewallEventHandler::Trigger_OnStopSpawningFuelPuddles(this);
		bSprayingFuel = false;
		bSpawningFuelPuddles = false;

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

	void StartIgniting(float DamagePerSec, float BurnTime)
	{
		DamagePerSecond = DamagePerSec;
		IgnitionStartTime = Time::GameTimeSeconds;
		bIgnitionFlame = true;
		bSprayingFuel = false;
		bSpawningFuelPuddles = false;
		BurnDuration = BurnTime;
	}

	void StopIgniting(float DissipateDelay)
	{
		if (bIgnitedFuel) 
			UIslandWalkerFueledFirewallEventHandler::Trigger_OnStopSpawningFire(this);
		bIgnitionFlame = false;
		bIgnitedFuel = false;
		bStoppedIgniting = true;
		DissipateTime = Time::GameTimeSeconds + DissipateDelay;
		ExpirationTime = DissipateTime + Settings.FirewallPostDissipateRemainDuration;
	}

	FVector GetTargetLocation() const property
	{
		FVector TargetLoc = Flamethrower.TargetLocation;
		if (ExtraOffset > SMALL_NUMBER)		
			TargetLoc += Flamethrower.SpreadDirection * ExtraOffset;
		if (Arena != nullptr)
			return Arena.GetFloorLocation(TargetLoc);
		return TargetLoc;
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
			UIslandWalkerFueledFirewallEventHandler::Trigger_OnFireBecomesHarmless(this);
		}
		if (bDissipating)
			return;

		if (bSprayingFuel)
		{
			float SprayRange = (CurTime - SprayFuelStartTime) * Settings.FirewallSprayFuelSpeed;
			if (!bSpawningFuelPuddles && (SprayRange > Flamethrower.SprayDistance + ExtraOffset * 0.25))
			{
				// Start building fuel line
				bSpawningFuelPuddles = true;
				UIslandWalkerFueledFirewallEventHandler::Trigger_OnStartSpawningFuelPuddles(this); 
				Line.Add(LineHead.Value);
				IgnitionTimes.Add(BIG_NUMBER);
			}
		}	

		if (bSpawningFuelPuddles)
		{
			// Spray has impacted, keep up with target location
			LineHead.AccelerateTo(TargetLocation, 0.5, DeltaTime);
			ActorLocation = LineHead.Value; 
			if (ShouldUpdateLineEnd(LineHead.Value))
			{
				LineDir = (LineHead.Value - Line.Last()).GetSafeNormal();
				Line.Add(LineHead.Value);
				IgnitionTimes.Add(BIG_NUMBER);
			}
		}	

		if (bIgnitionFlame)
		{
			float FlameRange = (CurTime - IgnitionStartTime) * Settings.FirewallIgnitionFlameSpeed;
			if (!bIgnitedFuel && (FlameRange > Flamethrower.SprayDistance + ExtraOffset * 0.25))
			{
				// Start setting fuel on fire!
				bIgnitedFuel = true; 
				UIslandWalkerFueledFirewallEventHandler::Trigger_OnStartSpawningFire(this); 
				IgnitionIndex = IgnitionTimes.Num() - 1;
				if (IgnitionTimes.IsValidIndex(IgnitionIndex))
					IgnitionTimes[IgnitionIndex] = Time::GetGameTimeSince(IgnitionStartTime);
				else 
					IgnitionIndex = 0; // TODO: Handle insta-ignition
			}
		}

		if (bIgnitedFuel)
		{
			LineHead.AccelerateTo(TargetLocation, 0.2, DeltaTime);
			ActorLocation = LineHead.Value;

			if (IgnitionIndex > 0) 
			{
				// Ignite the line from end to start
				FVector PrevLoc = Line[IgnitionIndex];
				FVector NextLoc = Line[IgnitionIndex - 1];
				if ((NextLoc - PrevLoc).DotProduct(ActorLocation - NextLoc) > 0.0)
				{
					// We've passed the next location in the line
					IgnitionIndex--;
					IgnitionTimes[IgnitionIndex] = Time::GetGameTimeSince(IgnitionStartTime);
				} 	
			}
		}

		if (bIgnitedFuel || bStoppedIgniting)
		{
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
		}

		DebugDraw();
	}

	bool ShouldUpdateLineEnd(FVector CurLoc)
	{
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

		// Check if last point should burn out or be moved towards the front of the line
		float SegmentAge = IgnitionAge - IgnitionTimes.Last();
		if (SegmentAge > BurnDuration)
		{
			int i = IgnitionTimes.Num() - 1;
			if ((i == 0) || (IgnitionAge - IgnitionTimes[i - 1] > BurnDuration))
			{
				// Previous point is also too old, snuff this one out
				Line.SetNum(i);
				IgnitionTimes.SetNum(i);
				if (IgnitionIndex >= i)
					IgnitionIndex = Math::Max(0, i - 1);
				return;
			}

			// Shrink line here	
			float NextIgnitionTime = IgnitionTimes[i - 1];
			FVector NextLoc = Line[i - 1];
			if (IgnitionTimes[i - 1] > BIG_NUMBER * 0.9)
			{
				// Next point hasn't been ignited yet
				NextLoc = CurLoc;
				NextIgnitionTime = IgnitionAge;
			}
			float SegmentTimeSpan = NextIgnitionTime - IgnitionTimes[i];
			float ShrinkFraction = (SegmentAge - BurnDuration) / SegmentTimeSpan;
			Line[i] = Math::Lerp(Line[i], NextLoc, ShrinkFraction);
			IgnitionTimes[i] = IgnitionAge - BurnDuration;
		}
	}

	bool IsAffectedByFire(AHazePlayerCharacter Player)
	{
		if (!bIgnitedFuel)
			return false;

		FVector PlayerLoc = Player.ActorCenterLocation;
		FVector ProjectedLoc;
		float Dummy;

		// When high enough above arena we can avoid damage when in lots of special moves
		if (Flamethrower.IsImmuneDueToShenanigans(Player, Arena.Height + Settings.FirewallDamageShenanigansHeight))
			return false;

		if (bIgnitionFlame)
		{
			// Are being hit by igniting flame itself?
			Math::ProjectPositionOnLineSegment(Flamethrower.LaunchLocation, ActorLocation, PlayerLoc, ProjectedLoc, Dummy); 
			if (PlayerLoc.Z > ProjectedLoc.Z)
				ProjectedLoc.Z = Math::Min(PlayerLoc.Z, ProjectedLoc.Z + Settings.FirewallDamageRadius * 0.5); // Fire reaches higher than radius
			if (PlayerLoc.IsWithinDist(ProjectedLoc, Settings.FirewallIgnitionFlameDamageRadius)) 
				return true;
		}

		// Check if target is within ignited line
		FVector CurLoc = ActorLocation;
		for (int i = IgnitionIndex; i < Line.Num(); i++)
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

	FVector GetFuelSpreadDirection() const
	{
		return LineDir;
	}

	FVector GetFireSpreadDirection() const
	{
		if (!bIgnitedFuel)
			return FVector::ZeroVector;
 		if (!Line.IsValidIndex(IgnitionIndex))
			return FVector::ZeroVector;
		if (IgnitionIndex == 0)
			return (ActorLocation - Line[IgnitionIndex]).GetSafeNormal2D();		
		return (Line[IgnitionIndex - 1] - Line[IgnitionIndex]).GetSafeNormal2D();		
	}

	// Get an array of evenly distributed locations along the fuel line (for audio)
	UFUNCTION(BlueprintPure)
	void GetFuelSpread(TArray<FVector>&out OutLocations, float Interval = 300.0)
	{
		if (Line.Num() == 0)
			return;
		if (bDissipating)
			return;
		
		// Fuel spread from line head to last unignited entry in line
		// and then continues backwards through the rest of the line.
		FVector PrevLoc = LineHead.Value;
		int iFuelEnd = Line.Num() - 1;
		if (bIgnitedFuel || bStoppedIgniting)
			iFuelEnd = IgnitionIndex - 1;	
		OutLocations.Add(PrevLoc);
		float RemainingDist = Interval;
		for (int iLine = iFuelEnd; iLine >= 0; iLine--)
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

	// Get an array of evenly distributed locations along the ignited line (for audio)
	UFUNCTION(BlueprintPure)
	void GetFireSpread(TArray<FVector>&out OutLocations, float Interval = 300.0)
	{
		if (Line.Num() == 0)
			return;
		if (bDissipating)
			return;
		if (!bIgnitedFuel && !bStoppedIgniting)
			return;

		// Fire spread from the line head to first ignited index in line
		// and continues to the end of line
		FVector PrevLoc = LineHead.Value;
		OutLocations.Add(PrevLoc);
		float RemainingDist = Interval;
		for (int iLine = IgnitionIndex; iLine < Line.Num(); iLine++)
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
		if (Line.Last().IsWithinDist(OutLocations.Last(), Interval * 0.5))
			OutLocations.Last() = Line.Last();
		else
			OutLocations.Add(Line.Last());
	}

	void DebugDraw()
	{
#if EDITOR
		WalkerFirewallDevToggles::DebugDrawFirewall.MakeVisible();
		if (WalkerFirewallDevToggles::DebugDrawFirewall.IsEnabled())
		{
			FVector Offset = FVector(0.0, 0.0, 10.0);
			if (bIgnitionFlame)
				Debug::DrawDebugLine(Flamethrower.LaunchLocation, ActorLocation, FLinearColor::DPink, 20.0); 

			// Fuel line
			FVector NextLoc = ActorLocation;
			if (bIgnitedFuel && (Line.Num() > 0))
				NextLoc = Line.Last(); 
			for (int i = Line.Num() - 1; i >= 0; i--)
			{
				Debug::DrawDebugLine(Line[i] + Offset, NextLoc + Offset, FLinearColor::Purple, 10.0);
				NextLoc = Line[i];
			}
			Debug::DrawDebugSphere(TargetLocation + Offset, 50.0, 4, FLinearColor::Purple, 5.0);
			Debug::DrawDebugArrow(TargetLocation + Offset + FVector(0.0, 0.0, 50.0), TargetLocation + Offset + FVector(0.0, 0.0, 50.0) + GetFuelSpreadDirection() * 100.0, 20.0, FLinearColor::Purple, 5.0);

			if (GetFuelSpreadDirection().IsZero() && (Line.Num() > 0))
				Debug::DrawDebugLine(TargetLocation, TargetLocation + FVector(0,0,1000), FLinearColor::Teal, 1.0, 0.5);
			if (bIgnitedFuel && GetFireSpreadDirection().IsZero())
				Debug::DrawDebugLine(TargetLocation, TargetLocation + FVector(0,0,1000), FLinearColor::DPink, 1.0, 0.5);

			if (bIgnitedFuel)
			{
				// Fire
				FVector CurLoc = ActorLocation;
				for (int i = IgnitionIndex; i < Line.Num(); i++)
				{
					Debug::DrawDebugLine(CurLoc + Offset, Line[i] + Offset, FLinearColor::Red, 20.0);
					CurLoc = Line[i];
				}
				Debug::DrawDebugSphere(TargetLocation + Offset, 50.0, 4, FLinearColor::Red, 10.0);
				if (Line.IsValidIndex(IgnitionIndex))
					Debug::DrawDebugSphere(Line[IgnitionIndex] + Offset, 20.0, 4, FLinearColor::Yellow, 5.0);
				Debug::DrawDebugArrow(TargetLocation + Offset + FVector(0.0, 0.0, 50.0), TargetLocation + Offset + FVector(0.0, 0.0, 50.0) + GetFireSpreadDirection() * 100.0, 20.0, FLinearColor::Red, 5.0);

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
		}
#endif
	}	
}

UCLASS(Abstract)
class UIslandWalkerFueledFirewallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	TArray<UNiagaraComponent> FireFX;

	UPROPERTY()
	TArray<UHazeDecalComponent> FuelDecals;

	UPROPERTY()
	bool bSpawningFuel = false;

	UPROPERTY()
	bool bSpawningFire = false;

	UPROPERTY()
	float FuelDecalInterval = 300.0;

	UPROPERTY()
	float FireInterval = 300.0;

	UPROPERTY(BlueprintReadOnly)
	UIslandWalkerFlameThrowerComponent FlameThrower;

	UPROPERTY(BlueprintReadOnly)
	AIslandWalkerFueledFirewall Firewall;

	TArray<UHazeDecalComponent> ReusableFuelDecals;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Firewall = Cast<AIslandWalkerFueledFirewall>(Owner);
		Firewall.OnPrepared.AddUFunction(this, n"OnPrepared");
	}

	UFUNCTION()
	private void OnPrepared(UIslandWalkerFlameThrowerComponent _FlameThrower)
	{
		FlameThrower = _FlameThrower;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSpawningFuelPuddles() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSpawningFuelPuddles() {}

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
	FVector GetFuelSpreadDirection() const
	{
		if (!ensure(Firewall != nullptr))
			return FVector::ZeroVector;
		return Firewall.GetFuelSpreadDirection();		
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

		// Wait until we've established a spread direction
		if (GetFireSpreadDirection().IsZero())
			return false;		

		if (FireFX.Num() == 0)
			return true;

		if (FireFX.Last().WorldLocation.IsWithinDist(Firewall.ActorLocation, FireInterval))
			return false;
		return true;	
	}

	UFUNCTION(BlueprintPure)
	bool ShouldDissipateFire(UNiagaraComponent Fire) const
	{
		if (Fire == nullptr)
			return true;

		if (Firewall.Line.Num() == 0)
			return false; // Line hasn't started yet

		if (Fire.WorldLocation.IsWithinDist2D(Firewall.Line[0], FireInterval * 0.5))
			return false; // Close to start of line, keep cloud	

		FVector LineStartDir = (Firewall.Line.Num() == 1) ? (Firewall.ActorLocation - Firewall.Line[0]) : (Firewall.Line[1] - Firewall.Line[0]);
		LineStartDir = LineStartDir.GetSafeNormal();
		if (LineStartDir.DotProduct(Fire.WorldLocation - Firewall.Line[0]) > 0.0)
			return false; // Ahead of last segment on line, keep cloud

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldSpawnFuelDecal() const
	{
		if (!bSpawningFuel)
			return false;

		// Wait until we've established a spread direction
		if (GetFuelSpreadDirection().IsZero())
			return false;		

		if (FuelDecals.Num() == 0)
			return true;

		if (FuelDecals.Last().WorldLocation.IsWithinDist(Firewall.ActorLocation, FuelDecalInterval))
			return false;

		return true;	
	}

	UFUNCTION(BlueprintCallable)
	UHazeDecalComponent SpawnFuelDecal(FVector Location, UMaterialInterface Material)
	{
		UHazeDecalComponent Decal;
		if (ReusableFuelDecals.Num() > 0)
		{
			Decal = ReusableFuelDecals.Last();
			ReusableFuelDecals.RemoveAt(ReusableFuelDecals.Num() - 1);
			Decal.RemoveComponentVisualsBlocker(this);
		}
		else 
		{
			// Spawn a new decal
			Decal = UHazeDecalComponent::Create(Owner);
			Decal.DetachFromParent(true);
		}

		Decal.DecalMaterial = Material;
		Decal.WorldLocation = Location;
		return Decal;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldRemoveLastFuelDecal()
	{
		if (FuelDecals.Num() == 0)
			return false;

		if (FireFX.Num() == 0)
			return false;
		
		FVector LastFuelLoc = FuelDecals.Last().WorldLocation;
		FVector LastFireLoc = FireFX.Last().WorldLocation;
		if (LastFuelLoc.IsWithinDist2D(LastFireLoc, Math::Max(FireInterval, FuelDecalInterval)))
			return true; // Close enough to ignite!

		if (GetFuelSpreadDirection().DotProduct(LastFuelLoc - LastFireLoc) > 0.0)
			return true; // Fire is behind fuel so has passed over and ignited it

		return false;
	}

	UFUNCTION()
	void RemoveLastFuelDecal()
	{
		UnspawnFuelDecal(FuelDecals.Last());
		FuelDecals.RemoveAt(FuelDecals.Num() - 1);
	}

	UFUNCTION()
	void UnspawnFuelDecal(UHazeDecalComponent Decal)
	{
		Decal.AddComponentVisualsBlocker(this);
		ReusableFuelDecals.Add(Decal);
	}
}


