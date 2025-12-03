enum EKnightSwordGlowInstigators
{
	SingleSlash,
	DualSlash,
	SpinningSlash,
	SmashGround,
	SlamStabGround,
}

UCLASS(Abstract)
class USummitKnightEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(Transient)
	TMap<USceneComponent, UNiagaraComponent> SummonCritterTrails;

	TArray<EKnightSwordGlowInstigators> SwordGlowInstigators;

	float CurrentSwordGlowAlpha;
	float ApplySwordGlowAlphaSpeed = 0.5;
	float ClearSwordGlowAlphaSpeed = 0.5;

	UFUNCTION()
	void ApplySwordGlow(EKnightSwordGlowInstigators Instigator, float Duration = 1.0)
	{
		SwordGlowInstigators.AddUnique(Instigator);
		
		// Always use the latest set speed, they should rarely affect each other
		ApplySwordGlowAlphaSpeed = 1.0 / Math::Max(0.1, Duration);
	}

	UFUNCTION()
	void ClearSwordGlow(EKnightSwordGlowInstigators Instigator, float Duration = 1.0)
	{
		SwordGlowInstigators.RemoveSwap(Instigator);

		// Always use the latest set speed, they should rarely affect each other
		ClearSwordGlowAlphaSpeed = 1.0 / Math::Max(0.1, Duration);
	}

	UFUNCTION()
	void ClearAllSwordGlow(float Duration = 1.0)
	{
		SwordGlowInstigators.Reset();

		// Always use the latest set speed, they should rarely affect each other
		ClearSwordGlowAlphaSpeed = 1.0 / Math::Max(0.1, Duration);
	}

	UFUNCTION()
	void UpdateSwordGlow(float DeltaTime)
	{
		if (SwordGlowInstigators.Num() > 0)
			CurrentSwordGlowAlpha += ApplySwordGlowAlphaSpeed * DeltaTime;	
		else
			CurrentSwordGlowAlpha -= ClearSwordGlowAlphaSpeed * DeltaTime;	
		CurrentSwordGlowAlpha = Math::Clamp(CurrentSwordGlowAlpha, 0.0, 1.0);			

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreenScaled("\nSword glow alpha: " + CurrentSwordGlowAlpha);	
#endif
	}

	UFUNCTION(BlueprintPure)
	float GetSwordGlowAlpha() const
	{
		return CurrentSwordGlowAlpha;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashTelegraph(FSummitKnightPlayerParams Params) {}

	// If both players are hit by blade
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashDirectHitBoth() {}
	
	// When a single player is hit by blade itself
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashDirectHit(FSummitKnightPlayerParams Params) {} 
	
	// When a single player gets knocked back from almost being hit by blade (may trigger for both)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashNearHit(FSummitKnightPlayerParams Params) {}
	
	// When a player is hit by shockwave but not blade itself
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashShockwaveHit(FSummitKnightPlayerParams Params) {}

	// When sword ground impact starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashImpact() {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashImpactGround() {} 
	
	// When both players avoid hits altogether
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashMiss(FSummitKnightPlayerParams Params) {} 

	// If attack was stopped (by tail dragon attack etc) before it was properly started
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSingleSlashAborted() {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashFirstTelegraph(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashSecondTelegraph(FSummitKnightPlayerParams Params) {}

	// If both players are hit by blade
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashFirstDirectHitBoth() {}

	// If both players are hit by blade
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashSecondDirectHitBoth() {}
	
	// When a single player is hit by blade itself
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashFirstDirectHit(FSummitKnightPlayerParams Params) {} 

	// When a single player is hit by blade itself
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashSecondDirectHit(FSummitKnightPlayerParams Params) {} 

	// When sword ground impact starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashFirstImpact() {} 

	// When sword ground impact starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDualSlashSecondImpact() {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinningSlashTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinningSlashStart(FSummitKnightMeleeShockwaveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinningSlashStartLoop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinningSlashEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinningSlashAborted() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalBottomDeploy(FSummitKnightCrystalBottomParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalBottomRetract(FSummitKnightCrystalBottomParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalBottomShatter(FSummitKnightCrystalBottomParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByRoll() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopTelegraph(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopChargeStart(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopChargeEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopHitPlayer(FSummitKnightPlayerParams Params) {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopAggroTelegraph(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopAggroStart(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopAggroEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwoopAggroHitPlayer(FSummitKnightPlayerParams Params) {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamDirectHitBoth() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamDirectHit(FSummitKnightPlayerParams Params) {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamShockwaveHit(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamMiss() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamImpact(FSummitKnightBladeImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamStartSwordPullout(FSummitKnightBladeImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamFreeSword(FSummitKnightBladeImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamAggroTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamAggroDirectHitBoth() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamAggroDirectHit(FSummitKnightPlayerParams Params) {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamAggroMiss() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlamAggroEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroFirstTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroFinalTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroFirstImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroFinalImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroDirectHitBoth() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroDirectHit(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroNearHit(FSummitKnightPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAggroMiss() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundAborted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashGroundEnd() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartCirlingAngry() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAlmostDeadReaction() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphLargeAreaStrike() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLargeAreaStrikePatternStart(FSummitKnightLargeAreaStrikeParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLargeAreaStrikePatternImpact(FSummitKnightLargeAreaStrikeParams Params) {}
		
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLargeAreaStrikeStop() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphHomingFireballs(FSummitKnightLaunchProjectileParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLaunchingHomingFireballs(FSummitKnightLaunchProjectileParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchHomingFireball(FSummitKnightLaunchProjectileParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLaunchingHomingFireballs(FSummitKnightLaunchProjectileParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopHomingFireballs() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireballImpact(FSummitKnightProjectileImpactParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphTrackingFlames() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLaunchingTrackingFlames() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchTrackingFlames(FSummitKnightTrackingFlamesParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrackingFlameImpact(FSummitKnightTrackingFlameImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopTrackingFlames() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAllTrackingFlamesExpired() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphSummonCritters() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSummoningCritters() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSummonCrittersBlobsLaunched(FSummitKnightLaunchCritterBlobsParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSummonedCritterBlobImpact(FSummitKnightLaunchCritterBlobParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSummonedCritterEmerge(FSummitKnightCritterEmergeParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSummoningCritters() {}


	UFUNCTION(BlueprintPure)
	FVector GetOwnerArenaLocation() const
	{
		USummitKnightComponent KnightComp = USummitKnightComponent::Get(Owner);
		if (KnightComp != nullptr)
			return KnightComp.GetArenaLocation(Owner.ActorLocation, nullptr);
		return Owner.ActorLocation;
	}
	
	UFUNCTION(BlueprintPure)
	FVector GetArenaCenter()
	{
		return TListedActors<ASummitKnightMobileArena>().Single.Center;
	}
}

struct FSummitKnightPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSummitKnightPlayerParams(AHazePlayerCharacter HitPlayer)
	{
		Player = HitPlayer;
	}
}

struct FSummitKnightTrackingFlamesParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	int LaunchIndex = 0;

	FSummitKnightTrackingFlamesParams(AHazePlayerCharacter TargetPlayer, int Index)
	{
		Player = TargetPlayer;
		LaunchIndex = Index;
	}
}

struct FSummitKnightTrackingFlameImpactParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ASummitKnightCrystalTrail Flame;

	FSummitKnightTrackingFlameImpactParams(AHazePlayerCharacter TargetPlayer, ASummitKnightCrystalTrail _Flame)
	{
		Player = TargetPlayer;
		Flame = _Flame;
	}
}


struct FSummitKnightCrystalBottomParams
{
	UPROPERTY()
	USummitKnightMobileCrystalBottom Crystal;

	FSummitKnightCrystalBottomParams(USummitKnightMobileCrystalBottom CrystalBottom)
	{
		Crystal = CrystalBottom;
	}
}

struct FSummitKnightLaunchCritterBlobsParams
{
	UPROPERTY()
	USummitKnightCritterSummoningLaunchComponent LaunchComp;

	UPROPERTY()
	TArray<USummitKnightCritterSummoningBlob> Projectiles;
}

struct FSummitKnightLaunchCritterBlobParams
{
	UPROPERTY()
	USummitKnightCritterSummoningBlob Projectile;

	FSummitKnightLaunchCritterBlobParams(USummitKnightCritterSummoningBlob Blob)
	{
		Projectile = Blob;
	}
}

struct FSummitKnightCritterEmergeParams
{
	UPROPERTY()
	FVector EmergeLocation;

	UPROPERTY()
	AAISummitKnightCritter Critter;

	FSummitKnightCritterEmergeParams(FVector EmergeLoc, AAISummitKnightCritter SummonedCritter)
	{
		EmergeLocation = EmergeLoc;
		Critter = SummonedCritter;
	}
}


struct FSummitKnightBladeImpactParams
{
	UPROPERTY()
	USummitKnightBladeComponent Weapon;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FRotator ImpactRotation;

	FSummitKnightBladeImpactParams(USummitKnightBladeComponent Blade, USummitKnightComponent KnightComp)
	{
		Weapon = Blade;	
		FVector BladeTipLoc = Blade.TipLocation;	
		ImpactLocation = BladeTipLoc;
		ImpactLocation.Z = KnightComp.GetArenaHeight();
		FVector BladeFwd = -Blade.RightVector;
		if (Math::Abs(BladeFwd.DotProduct(FVector::UpVector)) > 0.999)
			BladeFwd = (BladeTipLoc - KnightComp.Owner.ActorLocation).GetSafeNormal2D();
		ImpactRotation = FRotator::MakeFromZX(FVector::UpVector, BladeFwd);
	}
}

struct FSummitKnightSceptreImpactParams
{
	UPROPERTY()
	USummitKnightSceptreComponent Weapon;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FRotator ImpactRotation;

	FSummitKnightSceptreImpactParams(USummitKnightSceptreComponent Sceptre, ASummitKnightMobileArena Arena)
	{
		Weapon = Sceptre;
		ImpactLocation = Arena.GetAtArenaHeight(Sceptre.HeadLocation);
		ImpactRotation = FRotator::MakeFromZX(FVector::UpVector, Sceptre.UpVector);
	}
}

struct FSummitKnightMeleeShockwaveParams
{
	UPROPERTY()
	USummitKnightBladeComponent Weapon;

	FSummitKnightMeleeShockwaveParams(USummitKnightBladeComponent MeleeWeapon)
	{
		Weapon = MeleeWeapon;		
	}
}

struct FSummitKnightLaunchProjectileParams
{
	UPROPERTY()
	FVector LaunchLocation;

	FSummitKnightLaunchProjectileParams(FVector LaunchLoc)
	{
		LaunchLocation = LaunchLoc;
	}
}

struct FSummitKnightProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	FSummitKnightProjectileImpactParams(FVector ImpactLoc)
	{
		ImpactLocation = ImpactLoc;
	}
}

struct FSummitKnightLargeAreaStrikeParams
{
	UPROPERTY()
	ASummitDragonSlayerAoePattern Pattern;

	FSummitKnightLargeAreaStrikeParams(ASummitDragonSlayerAoePattern _Pattern)
	{
		Pattern = _Pattern;
	}
}

struct FSummitKnightHeadDamageParams
{
	UPROPERTY()
	USummitKnightHeadComponent Head;

	FSummitKnightHeadDamageParams(USummitKnightHeadComponent HeadComp)
	{
		Head = HeadComp;		
	}
}

