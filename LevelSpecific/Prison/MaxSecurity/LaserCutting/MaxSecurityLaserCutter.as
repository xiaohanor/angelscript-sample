#if !RELEASE
namespace DevToggleMaxSecurity
{
	const FHazeDevToggleBool DisableLaserCutterObstacles;
}
#endif

struct FMaxSecurityLaserCutterSyncedData
{
	FVector RootRelativeLocation;
	FQuat RootWorldRotation;
	bool bLaserIsImpactingWeakPoint;
};

UCLASS()
class UMaxSecurityLaserCutterCrumbSyncedComponent : UHazeCrumbSyncedStructComponent
{
	default SyncRate = EHazeCrumbSyncRate::High;

	void InterpolateValues(FMaxSecurityLaserCutterSyncedData& OutValue, FMaxSecurityLaserCutterSyncedData A, FMaxSecurityLaserCutterSyncedData B, float Alpha) const
	{
		OutValue.RootRelativeLocation = Math::Lerp(A.RootRelativeLocation, B.RootRelativeLocation, Alpha);
		OutValue.RootWorldRotation = FQuat::Slerp(A.RootWorldRotation, B.RootWorldRotation, Alpha);
		OutValue.bLaserIsImpactingWeakPoint = B.bLaserIsImpactingWeakPoint;
	}
}

event void FLaserCutterMioDiedEvent();

UCLASS(Abstract)
class AMaxSecurityLaserCutter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent CutterRoot;

	UPROPERTY(DefaultComponent, Attach = CutterRoot)
	USceneComponent EmitterRoot;

	UPROPERTY(DefaultComponent, Attach = EmitterRoot)
	USceneComponent LaserRoot;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	USceneComponent ImpactRoot;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UNiagaraComponent ChargeEffectComp;

	UPROPERTY(DefaultComponent, Attach = EmitterRoot)
	URemoteHackingResponseComponent HackingResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UMaxSecurityLaserCutterCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMaxSecurityLaserCutterStunnedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMaxSecurityLaserCutterLaserCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UMaxSecurityLaserCutterCrumbSyncedComponent SyncComponent;
	default SyncComponent.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMaxSecurityLaserCutterLaser> LaserClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ChargeLaserCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MegaLaserActivatedCameraShake;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike AlignWithPointTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SweepTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SplineSweepTimeLike;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ChasePlayerSpline;

	UPROPERTY(EditDefaultsOnly)
	FText TutorialText;

	bool bFollowingSpline = false;

	UPROPERTY()
	FRemoteHackingEvent OnHacked;

	UPROPERTY()
	FRemoteHackingEvent OnHackLaunchStarted;

	UPROPERTY(EditAnywhere)
	bool bRetracted = false;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineSweepSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor HeightModifierSpline;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bLaserActive = false;
	bool bImpactEffectActive = false;

	float LaserLength = 0.0;

	TArray<AMaxSecurityLaserCutterLaser> LaserBeams;
	AMaxSecurityLaserCutterLaser MainLaser;

	float MinLaserArrayPitch = -60.0;
	float MaxLaserArrayPitch = -90.0;
	float LaserArrayPitch = -15.0;

	FHazeAcceleratedFloat AccPitch;

	bool bMegaLaserActivated = false;

	float CurrentChargeTime = 0.0;
	float ChargeDuration = 1.0;
	float HackedChargeDuration = 1.2;

	int Stunners = 0;
	FRotator StunRotation;
	bool bStunned = false;

	float ChargeUpLength = 4000.0;
	float MaxLength = 30000.0;

	UPROPERTY(NotVisible)
	bool bAlignedToMid = false;

	FRotator AlignStartRotation;
	FRotator AlignTargetRotation;

	bool bSweepQueued = false;
	bool bSplineSweepQueued = false;

	FVector SweepTargetLocation;
	FRotator SweepStartRotation;
	FRotator SweepTargetRotation;

	bool bRevealed = false;

	bool bLaserEnabled = true;

	float ChaseAlpha = 0.0;
	bool bChasingPlayers = false;
	float ChaseDistance = 0.0;
	float MaxSpeed = 1200.0;
	float MinSpeed = 400.0;

	bool bHackInitiated = false;

	bool bPlayerControlled = false;

	bool bLasersSpawned = false;

	bool bExtraPlayerDamageTraceActive = true;

	UPROPERTY()
	FLaserCutterMioDiedEvent OnMioDied;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Always controlled from hacking side
		SetActorControlSide(Game::Mio);

		HackingResponseComp.OnLaunchStarted.AddUFunction(this, n"HackLaunchStarted");
		HackingResponseComp.OnHackingStarted.AddUFunction(this, n"Hacked");
		LaserArrayPitch = MinLaserArrayPitch;

		if (bRetracted)
			BaseComp.SetRelativeLocation(FVector(0.0, 0.0, 4000.0));

		AlignWithPointTimeLike.BindUpdate(this, n"UpdateAlignWithPoint");
		AlignWithPointTimeLike.BindFinished(this, n"FinishAlignWithPoint");

		SweepTimeLike.BindUpdate(this, n"UpdateSweep");
		SweepTimeLike.BindFinished(this, n"FinishSweep");

		SplineSweepTimeLike.BindUpdate(this, n"UpdateSplineSweep");
		SplineSweepTimeLike.BindFinished(this, n"FinishSplineSweep");

		// Disable ticking, enables when revealed
		AddActorTickBlock(this);
		CapabilityComp.AddComponentTickBlocker(this);

#if !RELEASE
		DevToggleMaxSecurity::DisableLaserCutterObstacles.MakeVisible();
#endif
	}

	UFUNCTION()
	void AlignWithPoint(FVector Loc)
	{
		AlignStartRotation = CutterRoot.WorldRotation;
		AlignTargetRotation = FRotator::MakeFromZ((CutterRoot.WorldLocation - Loc).GetSafeNormal());
		AlignWithPointTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateAlignWithPoint(float CurValue)
	{
		FRotator Rot = Math::LerpShortestPath(AlignStartRotation, AlignTargetRotation, CurValue);
		CutterRoot.SetWorldRotation(Rot);
	}

	UFUNCTION()
	private void FinishAlignWithPoint()
	{
		if (bLaserEnabled)
			ActivateLaser();
	}

	UFUNCTION()
	void AlignAndSweep(FVector AlignLoc, FVector SweepLoc)
	{
		if (HackingResponseComp.bHacked)
			return;

		bSweepQueued = true;
		SweepTargetLocation = SweepLoc;
		AlignWithPoint(AlignLoc);
	}

	UFUNCTION()
	void Sweep()
	{
		if (HackingResponseComp.bHacked)
			return;

		bSweepQueued = false;
		SweepStartRotation = CutterRoot.WorldRotation;
		SweepTargetRotation = FRotator::MakeFromZ((CutterRoot.WorldLocation - SweepTargetLocation).GetSafeNormal());
		SweepTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateSweep(float CurValue)
	{
		FRotator Rot = Math::LerpShortestPath(SweepStartRotation, SweepTargetRotation, CurValue);
		CutterRoot.SetWorldRotation(Rot);
	}

	UFUNCTION()
	private void FinishSweep()
	{

	}

	UFUNCTION()
	void AlignAndSplineSweep()
	{
		if (bChasingPlayers)
			return;

		if (!HasControl())
			return;

		FTransform Transform = GetSplineTransformOffsetFromPlayers(-1000.0);
		CrumbAlignAndSplineSweep(Transform);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAlignAndSplineSweep(FTransform Transform)
	{
		DeactivateLaser();
		bSplineSweepQueued = true;

		if (!HackingResponseComp.IsHacked())
		{
			FVector Dir = (Transform.Location - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			SplineSweepSpline.SetActorRotation(Dir.Rotation());
		}
		AlignWithPoint(SplineSweepSpline.Spline.GetWorldLocationAtSplineFraction(0));
	}

	UFUNCTION()
	void TriggerSplineSweep()
	{
		if (bChasingPlayers)
			return;

		bSplineSweepQueued = false;
		SplineSweepTimeLike.PlayFromStart();
	}
	
	UFUNCTION()
	private void UpdateSplineSweep(float CurValue)
	{
		float Dist = Math::Lerp(0.0, SplineSweepSpline.Spline.SplineLength, CurValue);

		FVector TargetLoc = SplineSweepSpline.Spline.GetWorldLocationAtSplineDistance(Dist);
		FRotator Rot = FRotator::MakeFromZ((CutterRoot.WorldLocation - TargetLoc).GetSafeNormal());
		CutterRoot.SetWorldRotation(Rot);
	}

	UFUNCTION()
	private void FinishSplineSweep()
	{
		
	}

	UFUNCTION()
	void Reveal()
	{
		if (bRevealed)
			return;

		bRevealed = true;
		ChargeDuration = 1.0;
		BP_Reveal();

		UMaxSecurityLaserCutterEffectEventHandler::Trigger_Spawn(this);

		// Enable ticking
		RemoveActorTickBlock(this);
		CapabilityComp.RemoveComponentTickBlocker(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Reveal() {}

	UFUNCTION()
	void SnapReveal()
	{
		if (bRevealed)
			return;

		bRevealed = true;
		ChargeDuration = 1.0;
		BaseComp.SetRelativeLocation(FVector::ZeroVector);

		// Enable ticking
		RemoveActorTickBlock(this);
		CapabilityComp.RemoveComponentTickBlocker(this);
	}

	UFUNCTION()
	void SnapAlignToPoint(FVector Loc)
	{
		FRotator SnapAlignRot = FRotator::MakeFromZ((CutterRoot.WorldLocation - Loc).GetSafeNormal());
		CutterRoot.SetWorldRotation(SnapAlignRot);
	}

	UFUNCTION()
	private void HackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		bChasingPlayers = false;
		bHackInitiated = true;
		OnHackLaunchStarted.Broadcast();
	}

	UFUNCTION()
	private void Hacked()
	{
		DeactivateLaser();

		StopAllTimeLikes();

		OnHacked.Broadcast();

		ChargeDuration = HackedChargeDuration;

		UMaxSecurityLaserCutterEffectEventHandler::Trigger_Hacked(this);
	}

	UFUNCTION()
	void AlignToMid()
	{
		BP_AlignToMid();
	}

	UFUNCTION(BlueprintEvent)
	void BP_AlignToMid() {}

	UFUNCTION()
	void SetLaserEnabled(bool bEnabled)
	{
		bLaserEnabled = bEnabled;
	}

	UFUNCTION()
	void ActivateLaser()
	{
		if(!HasControl())
			return;

		if (bLaserActive)
			return;

		CrumbActivateLaser();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateLaser()
	{
		LaserLength = 0.0;
		CurrentChargeTime = 0.0;
		LaserArrayPitch = MinLaserArrayPitch;
		bLaserActive = true;

		if (bLasersSpawned)
		{
			for (int i = 0; i <= 7; i++)
			{
				LaserBeams[i].ActivateLaser();
			}
		}
		else
		{
			for (int i = 0; i <= 7; i++)
			{
				AMaxSecurityLaserCutterLaser LaserBeam = SpawnActor(LaserClass, LaserRoot.WorldLocation);
				LaserBeam.AttachToComponent(LaserRoot);
				LaserBeam.SetActorRelativeRotation(FRotator(0.0, 45.0 * i, 0.0));
				LaserBeams.Add(LaserBeam);
				if (MainLaser == nullptr)
					MainLaser = LaserBeam;
			}

			bLasersSpawned = true;
		}

		ChargeEffectComp.Activate(true);

		Game::Mio.PlayCameraShake(ChargeLaserCameraShake, this);

		UMaxSecurityLaserCutterEffectEventHandler::Trigger_ChargeUpStarted(this);
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		if(!HasControl())
			return;

		if (!bLaserActive)
			return;

		CrumbDeactivateLaser();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivateLaser()
	{
		bLaserActive = false;

		if (bMegaLaserActivated)
			UMaxSecurityLaserCutterEffectEventHandler::Trigger_LaserDeactivated(this);
		else
			UMaxSecurityLaserCutterEffectEventHandler::Trigger_ChargeUpStopped(this);

		bMegaLaserActivated = false;

		for (AMaxSecurityLaserCutterLaser Laser : LaserBeams)
		{
			if (Laser != nullptr)
				Laser.DeactivateLaser();
		}

		ChargeEffectComp.Deactivate();

		Game::Mio.StopCameraShakeByInstigator(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetLength = bLaserActive ? ChargeUpLength : 0.0;
		if (bMegaLaserActivated)
			TargetLength = MaxLength;

		LaserLength = Math::FInterpTo(LaserLength, TargetLength, DeltaTime, 5.0);

		if (bLaserActive)
		{
			CurrentChargeTime = Math::Clamp(CurrentChargeTime + DeltaTime, 0.0, ChargeDuration);
			float ChargeAlpha = CurrentChargeTime/ChargeDuration;
			LaserArrayPitch = Math::Lerp(MinLaserArrayPitch, MaxLaserArrayPitch, ChargeAlpha);

			if (ChargeAlpha >= 1.0)
				ActivateMegaLaser();
		}

		for (AMaxSecurityLaserCutterLaser Laser : LaserBeams)
		{
			Laser.Pitch = LaserArrayPitch;
			Laser.LaserLength = LaserLength;
		}

		if (bMegaLaserActivated)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseLine();
			Trace.IgnoreActor(this);

			FHitResult Hit = Trace.QueryTraceSingle(LaserRoot.WorldLocation, LaserRoot.WorldLocation - (LaserRoot.UpVector * LaserLength));
			if (Hit.bBlockingHit)
			{
				HandleMegaLaserHit(Hit);
			}
			else
			{
				ImpactRoot.SetWorldLocation(Hit.TraceEnd);
			}

			if (bExtraPlayerDamageTraceActive)
			{
				FHazeTraceSettings PlayerTrace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
				PlayerTrace.UseCapsuleShape(250.0, 3000.0, LaserRoot.WorldRotation.Quaternion());

				FOverlapResultArray Overlaps = PlayerTrace.QueryOverlaps(LaserRoot.WorldLocation + (LaserRoot.UpVector * -1500.0));
				for (FOverlapResult OverlapResult : Overlaps)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OverlapResult.Actor);
					if (Player != nullptr)
						Player.KillPlayer(FPlayerDeathDamageParams(), DeathEffect);
				}
			}
		}

		ChaseAlpha = GetFrontPlayerSplineDistance()/ChasePlayerSpline.Spline.SplineLength;

		if (bChasingPlayers && bMegaLaserActivated && !HackingResponseComp.bHacked && !AlignWithPointTimeLike.IsPlaying())
		{
			FVector TargetLoc = ChasePlayerSpline.Spline.GetWorldLocationAtSplineDistance(ChaseDistance);
			float Speed = Math::GetMappedRangeValueClamped(FVector2D(500.0, 1000.0), FVector2D(MinSpeed, MaxSpeed), ChasePlayerSpline.Spline.GetWorldLocationAtSplineDistance(GetBackPlayerSplineDistance()).Distance(TargetLoc));
			ChaseDistance += Speed * DeltaTime;

			FRotator TargetRot = FRotator::MakeFromZ((CutterRoot.WorldLocation - TargetLoc).GetSafeNormal());
			FRotator Rot = Math::RInterpShortestPathTo(CutterRoot.WorldRotation, TargetRot, DeltaTime, 5.0);
			CutterRoot.SetWorldRotation(Rot);
		}
	}

	private void HandleMegaLaserHit(FHitResult Hit)
	{
		check(Hit.bBlockingHit);

		if (!HackingResponseComp.bHacked)
		{
			if (HasControl())
			{
				AMaxSecurityLaserCutterPathPiece PathPiece = Cast<AMaxSecurityLaserCutterPathPiece>(Hit.Actor);
				if (PathPiece != nullptr && !PathPiece.IsDestroyed())
				{
					PathPiece.ControlDestroyPiece();
				}
			}
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		if (Player != nullptr)
			Player.KillPlayer(FPlayerDeathDamageParams(), DeathEffect);

		ImpactRoot.SetWorldLocation(Hit.ImpactPoint);

		FMaxSecurityLaserCutterImpactData ImpactData;
		ImpactData.HitResult = Hit;

		FMaxSecurityLaserCutterSyncedData SyncedData;
		SyncComponent.GetCrumbValueStruct(SyncedData);
		ImpactData.bIsImpactingWeakPoint = SyncedData.bLaserIsImpactingWeakPoint;

		UMaxSecurityLaserCutterEffectEventHandler::Trigger_LaserImpacting(this, ImpactData);
	}

	UFUNCTION()
	void SetChaseMinSpeed(float Speed)
	{
		MinSpeed = Speed;
	}

	UFUNCTION()
	void DisableExtraPlayerDamageTrace()
	{
		bExtraPlayerDamageTraceActive = false;
	}

	void ActivateMegaLaser()
	{
		if (bMegaLaserActivated)
			return;

		bMegaLaserActivated = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(MegaLaserActivatedCameraShake, this, 0.35);

		if (!HackingResponseComp.bHacked)
			StartFollowingSpline();

		if (bSweepQueued)
			Sweep();

		if (bSplineSweepQueued)
			TriggerSplineSweep();

		for (AMaxSecurityLaserCutterLaser Laser : LaserBeams)
		{
			if (Laser != MainLaser)
				Laser.DeactivateLaser();
			else
				Laser.ActivateAsMainLaser();
		}

		UMaxSecurityLaserCutterEffectEventHandler::Trigger_LaserActivated(this);
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		bFollowingSpline = true;
	}

	UFUNCTION()
	void StartChasingPlayers(float StartOffset = -200.0)
	{
		if (bChasingPlayers)
			return;

		bSweepQueued = false;
		bSplineSweepQueued = false;

		DeactivateLaser();

		StopAllTimeLikes();

		FVector StartLoc = GetSplineTransformOffsetFromPlayers(StartOffset).Location;
		ChaseDistance = ChasePlayerSpline.Spline.GetClosestSplineDistanceToWorldLocation(StartLoc);

		AlignWithPoint(StartLoc);
		bChasingPlayers = true;
	}

	UFUNCTION()
	void SweepBehindPlayers()
	{
		if (bChasingPlayers)
			return;

		if (!HasControl())
			return;

		FTransform Transform = GetSplineTransformOffsetFromPlayers(-200);

		FVector Dir = Transform.Rotation.Vector().RotateAngleAxis(-90.0, FVector::UpVector);
		Transform.Location = Transform.Location + (Dir * 1000.0);
		CrumbAlignAndSweep(Transform.Location, Transform.Location - (Dir * 2000.0));
	}

	UFUNCTION()
	void SweepAheadOfPlayers()
	{
		if (bChasingPlayers)
			return;

		if (!HasControl())
			return;
		
		FTransform Transform = GetSplineTransformOffsetFromPlayers(2400);

		FVector Dir = Transform.Rotation.Vector().RotateAngleAxis(-90.0, FVector::UpVector);
		Transform.Location = Transform.Location + (Dir * 1000.0);
		CrumbAlignAndSweep(Transform.Location, Transform.Location - (Dir * 2000.0));
	}

	UFUNCTION(CrumbFunction)
	void CrumbAlignAndSweep(FVector AlignLoc, FVector SweepLoc)
	{
		DeactivateLaser();
		AlignAndSweep(AlignLoc, SweepLoc);
	}

	FVector GetSweepStartLocation(FVector Loc, float Dist) const
	{
		FRotator SplineRot = ChasePlayerSpline.Spline.GetWorldRotationAtSplineDistance(Dist).Rotator();
		FVector Dir = SplineRot.Vector().RotateAngleAxis(-90.0, FVector::UpVector);
		return Loc + (Dir * 1000.0);
	}

	FTransform GetSplineTransformOffsetFromPlayers(float Offset) const
	{
		bool bForwards = Offset > 0;
		float SplineDist = bForwards ? GetFrontPlayerSplineDistance() : GetBackPlayerSplineDistance();
		float TargetDist = SplineDist + Offset;

		FVector TargetLoc = ChasePlayerSpline.Spline.GetWorldLocationAtSplineDistance(TargetDist);

		TListedActors<AMaxSecurityLaserCutterPathPiece> PathPieces;
		AMaxSecurityLaserCutterPathPiece ClosestPiece = PathPieces[0];
		for (AMaxSecurityLaserCutterPathPiece Piece : PathPieces)
		{
			float Dist = Piece.PieceCenter.WorldLocation.Distance(TargetLoc);
			if (Dist < ClosestPiece.PieceCenter.WorldLocation.Distance(TargetLoc))
				ClosestPiece = Piece;
		}

		float PieceDist = ChasePlayerSpline.Spline.GetClosestSplineDistanceToWorldLocation(ClosestPiece.PieceCenter.WorldLocation);

		FTransform Transform;
		Transform.Location = ClosestPiece.PieceCenter.WorldLocation;
		Transform.Rotation = ChasePlayerSpline.Spline.GetWorldRotationAtSplineDistance(PieceDist);

		return Transform;
	}

	float GetFrontPlayerSplineDistance() const
	{
		float ClosestDist = SMALL_NUMBER;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (!Player.IsPlayerDead())
			{
				float PlayerDist = ChasePlayerSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
				if (PlayerDist > ClosestDist)
					ClosestDist = PlayerDist;
			}
		}

		return ClosestDist;
	}

	float GetBackPlayerSplineDistance() const
	{
		float ClosestDist = BIG_NUMBER;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (!Player.IsPlayerDead())
			{
				float PlayerDist = ChasePlayerSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
				if (PlayerDist < ClosestDist)
					ClosestDist = PlayerDist;
			}
		}

		return ClosestDist;
	}

	void StopAllTimeLikes()
	{
		SweepTimeLike.Stop();
		SplineSweepTimeLike.Stop();
		AlignWithPointTimeLike.Stop();
	}

	void AddStunner()
	{
		Stunners++;
		if (Stunners == 1)
			StunRotation = CutterRoot.RelativeRotation;
	}

	void RemoveStunner()
	{
		Stunners--;
	}

	bool IsStunned() const
	{
		return bStunned;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Stunned() {}

	UFUNCTION(BlueprintEvent)
	void BP_Unstunned() {}

	float GetChargeAlpha() const
	{
		return CurrentChargeTime / ChargeDuration;
	}

	UFUNCTION()
	void SetPlayerControlled()
	{
		bPlayerControlled = true;
	}

	UFUNCTION()
	void BindMioDeathEvent()
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Game::Mio);
		HealthComp.OnDeathTriggered.AddUFunction(this, n"MioDied");
	}

	UFUNCTION()
	private void MioDied()
	{
		OnMioDied.Broadcast();
	}

	UFUNCTION()
	void UnbindMioDeathEvent()
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Game::Mio);
		HealthComp.OnDeathTriggered.UnbindObject(this);
	}
}

enum EMaxSecurityLaserCutterAttackType
{
	SweepAhead,
	SweepBehind,
	SplineSweepBehind,
	Chase
}

namespace MaxSecurityLaserCutter
{
	// Get the example listed actor in the level
	UFUNCTION()
	AMaxSecurityLaserCutter GetLaserCutter()
	{
		return TListedActors<AMaxSecurityLaserCutter>().GetSingle();
	}


}