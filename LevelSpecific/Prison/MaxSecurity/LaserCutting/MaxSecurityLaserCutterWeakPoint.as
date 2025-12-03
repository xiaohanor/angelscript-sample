event void FMaxSecurityLaserCutterWeakPointDestroyedEvent();

struct FMaxSecurityLaserCutterWeakPointHit
{
	FVector Location;
	bool bDestroyLocation;
};

class UMaxSecurityLaserCutterWeakPointMeshComponent : UStaticMeshComponent
{

}

UCLASS(Abstract)
class AMaxSecurityLaserCutterWeakPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WeakPointRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 14000.0;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh WeakPointIntactMesh;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh WeakPointBrokenMesh;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterClamp LeftClamp;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterClamp RightClamp;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterGuard LeftGuard;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterGuard RightGuard;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterWelderBot WelderBot;

	UPROPERTY(EditInstanceOnly)
	AActor GuardMid;

	UPROPERTY(EditAnywhere)
	bool bSpawnGuards = true;

	UPROPERTY(EditAnywhere)
	bool bSpawnWelders = true;

	UPROPERTY()
	FMaxSecurityLaserCutterWeakPointDestroyedEvent OnWeakPointDestroyed;

	bool bWeakPointDestroyed = false;

	TArray<UMaxSecurityLaserCutterWeakPointMeshComponent> WeakPointMeshComps;
	TArray<UMaxSecurityLaserCutterWeakPointMeshComponent> DestroyedMeshComps;

	float CompletionAlpha = 0.0;

	bool bClampsClosed = false;
	
	bool bGuardsActive = false;
	bool bLeftGuardActive = false;
	bool bRightGuardActive = false;
	float GuardCooldown = 15.0;
	float CurrentGuardCooldown = 0.0;

	bool bWelderBotActive = false;
	float WelderBotCooldown = 9.0;
	float CurrentWelderBotCooldown = 0.0;

	float CompletionRequired = 1.0;

	float GuardThreshold = 0.25;
	float WelderThreshold = 0.45;

	float SegmentOffsetFromCenter = 1025.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for (int i = 0; i <= 71; i++)
		{
			UMaxSecurityLaserCutterWeakPointMeshComponent MeshComp = UMaxSecurityLaserCutterWeakPointMeshComponent::Create(this, FName(f"Weakpoint {i}"));
			MeshComp.AttachToComponent(WeakPointRoot);
			MeshComp.SetStaticMesh(WeakPointIntactMesh);
			MeshComp.SetRelativeRotation(FRotator(0.0, i * 5.0, 0.0));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Always controlled from the laser cutter side
		SetActorControlSide(Game::Mio);

		GetComponentsByClass(UMaxSecurityLaserCutterWeakPointMeshComponent, WeakPointMeshComps);

		CurrentGuardCooldown = GuardCooldown;
		CurrentWelderBotCooldown = WelderBotCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Only control side can tick completion,
		// all events are crumbed anyway
		if (!HasControl())
			return;

		if (bWeakPointDestroyed)
			return;

		CompletionAlpha = Math::TruncToFloat(DestroyedMeshComps.Num())/Math::TruncToFloat(WeakPointMeshComps.Num());

		if (CompletionAlpha >= GuardThreshold)
		{
			if (!bLeftGuardActive && !bRightGuardActive)
			{
				CurrentGuardCooldown += DeltaTime;
				if (CurrentGuardCooldown >= GuardCooldown)
					ControlActivateGuards();
			}
		}

		if (CompletionAlpha >= WelderThreshold)
		{
			if (!bWelderBotActive)
			{
				CurrentWelderBotCooldown += DeltaTime;
				if (CurrentWelderBotCooldown >= WelderBotCooldown)
					ControlActivateWelderBot();
			}
		}

		if (CompletionAlpha >= CompletionRequired)
		{
			ControlWeakPointDestroyed();
		}
	}

	UFUNCTION()
	void SetPrecutPiecesBroken()
	{
		int Index = 0;
		for (UMaxSecurityLaserCutterWeakPointMeshComponent WeakPointComp : WeakPointMeshComps)
		{
			if (Index > 58 && Index < 67)
			{
				DestroyedMeshComps.Add(WeakPointComp);
				WeakPointComp.SetStaticMesh(WeakPointBrokenMesh);
			}

			Index++;
		}
	}

	void ControlHitByLaser(FHitResult HitResult)
	{
		check(HasControl());
		
		auto HitComp = Cast<UMaxSecurityLaserCutterWeakPointMeshComponent>(HitResult.Component);
		if (HitComp == nullptr)
			return;

		if (!WeakPointMeshComps.Contains(HitComp))
			return;

		if (!DestroyedMeshComps.Contains(HitComp))
		{
			CrumbHitByLaser(HitComp);
			DestroyedMeshComps.Add(HitComp);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHitByLaser(UMaxSecurityLaserCutterWeakPointMeshComponent HitComp)
	{
		HitComp.SetStaticMesh(WeakPointBrokenMesh);

		FMaxSecurityLaserCutterWeakPointEventParams Params;
		Params.Point = HitComp;
		Params.Location = HitComp.WorldLocation + (HitComp.RightVector * -SegmentOffsetFromCenter);
		UMaxSecurityLaserCutterWeakPointEffectEventHandler::Trigger_SegmentCut(this, Params);
	}

	void ControlRepairLocation(UMaxSecurityLaserCutterWeakPointMeshComponent Point)
	{
		if (!ensure(HasControl()))
			return;

		if (DestroyedMeshComps.Contains(Point))
			CrumbRepairLocation(Point);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRepairLocation(UMaxSecurityLaserCutterWeakPointMeshComponent Point)
	{
		Point.SetStaticMesh(WeakPointIntactMesh);
		DestroyedMeshComps.Remove(Point);

		FMaxSecurityLaserCutterWeakPointEventParams Params;
		Params.Point = Point;
		Params.Location = Point.WorldLocation + (Point.RightVector * -SegmentOffsetFromCenter);
		UMaxSecurityLaserCutterWeakPointEffectEventHandler::Trigger_SegmentRepaired(this, Params);
	}

	UFUNCTION()
	void SetAllSegmentsBroken()
	{
		for (UMaxSecurityLaserCutterWeakPointMeshComponent Mesh : WeakPointMeshComps)
		{
			Mesh.SetStaticMesh(WeakPointBrokenMesh);
		}
	}

	UFUNCTION(DevFunction)
	void DevDestroyWeakPoint()
	{
		if (HasControl())
			ControlWeakPointDestroyed();
	}

	void ControlWeakPointDestroyed()
	{
		if (!ensure(HasControl()))
			return;

		if (bWeakPointDestroyed)
			return;

		CrumbWeakPointDestroyed();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbWeakPointDestroyed()
	{
		bWeakPointDestroyed = true;
		OnWeakPointDestroyed.Broadcast();
	}

	void ControlCloseClamps()
	{
#if !RELEASE
		if(DevToggleMaxSecurity::DisableLaserCutterObstacles.IsEnabled())
			return;
#endif

		if (!ensure(HasControl()))
			return;

		if (bClampsClosed)
			return;

		CrumbCloseClamps();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCloseClamps()
	{
		bClampsClosed = true;

		LeftClamp.ActivateClamp();
		RightClamp.ActivateClamp();
	}

	void ControlActivateGuards()
	{
#if !RELEASE
		if(DevToggleMaxSecurity::DisableLaserCutterObstacles.IsEnabled())
			return;
#endif

		if (!ensure(HasControl()))
			return;

		if (!bSpawnGuards)
			return;

		if (bGuardsActive)
			return;

		CrumbActivateGuards();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateGuards()
	{
		bGuardsActive = true;

		LeftGuard.DropDown();
		RightGuard.DropDown();

		bLeftGuardActive = true;
		bRightGuardActive = true;
		CurrentGuardCooldown = 0.0;

		LeftGuard.OnGuardDestroyed.AddUFunction(this, n"LeftGuardDestroyed");
		RightGuard.OnGuardDestroyed.AddUFunction(this, n"RightGuardDestroyed");	
	}

	UFUNCTION()
	private void LeftGuardDestroyed()
	{
		bLeftGuardActive = false;
		if (bRightGuardActive)
			bGuardsActive = false;
	}

	UFUNCTION()
	private void RightGuardDestroyed()
	{
		bRightGuardActive = false;
		if (bLeftGuardActive)
			bGuardsActive = false;
	}

	void ControlActivateWelderBot()
	{
#if !RELEASE
		if(DevToggleMaxSecurity::DisableLaserCutterObstacles.IsEnabled())
			return;
#endif

		if (!ensure(HasControl()))
			return;

		if (!bSpawnWelders)
			return;

		if (bWelderBotActive)
			return;

		FVector PlayerDirToMid = (ActorLocation - Game::Zoe.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector OptimalLocation = ActorLocation + (PlayerDirToMid * SegmentOffsetFromCenter);

		UMaxSecurityLaserCutterWeakPointMeshComponent ClosestPrimaryDestroyedSegment = nullptr;
		float ClosestDestroyedSegmentDist = BIG_NUMBER;
		FVector ClosestPrimaryDestroyedSegmentLocation = FVector::ZeroVector;
		for (UMaxSecurityLaserCutterWeakPointMeshComponent Segment : DestroyedMeshComps)
		{
			float DistToSegment = OptimalLocation.Dist2D(Segment.WorldLocation + (Segment.RightVector * -SegmentOffsetFromCenter), FVector::UpVector);
			if (DistToSegment <= ClosestDestroyedSegmentDist)
			{
				ClosestPrimaryDestroyedSegment = Segment;
				ClosestDestroyedSegmentDist = DistToSegment;
				ClosestPrimaryDestroyedSegmentLocation = Segment.WorldLocation + (Segment.RightVector * -SegmentOffsetFromCenter);
			}
		}

		UMaxSecurityLaserCutterWeakPointMeshComponent ClosestSecondaryDestroyedSegment = nullptr;
		ClosestDestroyedSegmentDist = BIG_NUMBER;
		FVector ClosestSecondaryDestroyedSegmentLocation = FVector::ZeroVector;
		TArray<UMaxSecurityLaserCutterWeakPointMeshComponent> OtherDestroyedSegments = DestroyedMeshComps;
		OtherDestroyedSegments.Remove(ClosestPrimaryDestroyedSegment);
		for (UMaxSecurityLaserCutterWeakPointMeshComponent Segment : OtherDestroyedSegments)
		{
			float DistToSegment = ClosestPrimaryDestroyedSegmentLocation.Dist2D(Segment.WorldLocation + (Segment.RightVector * -SegmentOffsetFromCenter), FVector::UpVector);
			if (DistToSegment <= ClosestDestroyedSegmentDist)
			{
				ClosestSecondaryDestroyedSegment = Segment;
				ClosestDestroyedSegmentDist = DistToSegment;
				ClosestSecondaryDestroyedSegmentLocation = Segment.WorldLocation + (Segment.RightVector * -SegmentOffsetFromCenter);
			}
		}

		FVector DirToPrimarySegment = (ClosestPrimaryDestroyedSegmentLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector DirToSecondarySegment = (ClosestSecondaryDestroyedSegmentLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FVector SpawnLocation = ClosestPrimaryDestroyedSegmentLocation;
		SpawnLocation.Z = WelderBot.StartLocation.Z;

		FVector SegmentCross = DirToPrimarySegment.CrossProduct(DirToSecondarySegment);
		bool bForwardOnSpline = SegmentCross.Z > 0.0;

		CrumbActivateWelderBot(SpawnLocation, bForwardOnSpline);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateWelderBot(FVector SpawnLocation, bool bForwardOnSpline)
	{
		bWelderBotActive = true;
		WelderBot.Drop(SpawnLocation, bForwardOnSpline);
		
		WelderBot.OnBotDestroyed.AddUFunction(this, n"WelderBotDestroyed");
	}

	UFUNCTION()
	private void WelderBotDestroyed()
	{
		bWelderBotActive = false;
		CurrentWelderBotCooldown = 0.0;
	}

	UFUNCTION(DevFunction)
	void DevActivateGuards()
	{
		if (HasControl())
			ControlActivateGuards();
	}

	UFUNCTION(DevFunction)
	void DevActivateWelderBot()
	{
		if (HasControl())
			ControlActivateWelderBot();
	}
}

class UMaxSecurityLaserCutterWeakPointEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void SegmentCut(FMaxSecurityLaserCutterWeakPointEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void SegmentRepaired(FMaxSecurityLaserCutterWeakPointEventParams Params) {}
}

struct FMaxSecurityLaserCutterWeakPointEventParams
{
	UPROPERTY()
	UMaxSecurityLaserCutterWeakPointMeshComponent Point;

	UPROPERTY()
	FVector Location;
}