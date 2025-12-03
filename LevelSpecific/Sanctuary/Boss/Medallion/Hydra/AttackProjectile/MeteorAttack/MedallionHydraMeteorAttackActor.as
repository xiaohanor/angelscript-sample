enum EBallistaHydraMeteorTargetType
{
	None,
	A,
	B,
}

namespace MedallionHydraMeteorAttack
{
	const float DebugDrawDuration = 8.0;
}

class AMedallionHydraMeteorAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent LaunchProjectileRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent MovementQueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ProjectileQueueComp;

	UPROPERTY()
	TSubclassOf<AMedallionHydraMeteorProjectile> ProjectileClass;

	UBallistaHydraActorReferencesComponent BallistaRefs;
	UMedallionPlayerReferencesComponent MedallionRefsComp;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra Hydra;

	AHazePlayerCharacter TargetPlayer;

	const int ProjectilesToSpawn = 6;
	const float ArchDegrees = -120.0;
	const float ArchDuration = 1.0;

	EBallistaHydraMeteorTargetType LastTargetType;

	TArray<FMedallionHydraMeteorLeftToRightPlatformTargetData> TargetedPlatforms;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetPlayer = Game::Mio;
		BallistaRefs = UBallistaHydraActorReferencesComponent::GetOrCreate(TargetPlayer);
		MedallionRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION()
	void Activate()
	{
		MovementQueueComp.Duration(1.0, this, n"GetIntoPositionUpdate");

		LastTargetType = LastTargetType == EBallistaHydraMeteorTargetType::A ? EBallistaHydraMeteorTargetType::B : EBallistaHydraMeteorTargetType::A;
		MovementQueueComp.Event(this, n"StartLaunchProjectiles", LastTargetType);

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, EMedallionHydraMovePivotPriority::High, 1.0);
		Hydra.OneshotAnimation(EFeatureTagMedallionHydra::MeteorSpawn, AnimationDuration = 3.0);
		Hydra.BlockLaunchProjectiles(this);
		bActive = true;
	}

	UFUNCTION()
	private void GetIntoPositionUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
		FRotator Rotation = FRotator(0.0, 0.0, Math::Lerp(0.0, -ArchDegrees / 2, CurrentValue));
		RotateRoot.SetRelativeRotation(Rotation);
	}

	UFUNCTION()
	private void StartLaunchProjectiles(EBallistaHydraMeteorTargetType MeteorTargetType)
	{
		MovementQueueComp.Duration(ArchDuration, this, n"ArchUpdate");
		MovementQueueComp.Idle(1.0);
		MovementQueueComp.Event(this, n"PlayAttackAnimation");
		MovementQueueComp.Event(this, n"Deactivate");

		for (int i = 0; i < ProjectilesToSpawn - 1; i++)
		{
			ProjectileQueueComp.Event(this, n"SpawnProjectile");
			ProjectileQueueComp.Idle(ArchDuration / (ProjectilesToSpawn - 1));
		}

		ProjectileQueueComp.Event(this, n"SpawnProjectile");

		FSanctuaryBossMedallionManagerEventPlayerAttackData Params;
		Params.AttackType = EMedallionHydraAttack::Meteor;
		Params.Hydra = Hydra;
		Params.TargetPlayer = TargetPlayer;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnMeteorAttackStart(MedallionRefsComp.Refs.HydraAttackManager, Params);
	}	

	UFUNCTION()
	private void ArchUpdate(float Alpha)
	{
		float CurrentValue = Alpha;
		FRotator Rotation = FRotator(0.0, 0.0, Math::Lerp(-ArchDegrees / 2, ArchDegrees / 2, CurrentValue));
		RotateRoot.SetRelativeRotation(Rotation);
	}

	UFUNCTION()
	private void SpawnProjectile()
	{
		TargetPlayer = TargetPlayer.OtherPlayer;
		AMedallionHydraMeteorProjectile Projectile = SpawnActor(ProjectileClass, LaunchProjectileRoot.WorldLocation, LaunchProjectileRoot.WorldRotation, bDeferredSpawn = true);
		Projectile.Hydra = Hydra;
		FinishSpawningActor(Projectile);
		Projectile.QueueHover();
		FMedallionHydraMeteorProjectileData Data;
		Data.Projectile = Projectile;
		Projectile.QueueComp.Event(this, n"AssignPlatformTarget", Data);
		Projectile.QueueMeteor();
	}

	UFUNCTION()
	private void AssignPlatformTarget(FMedallionHydraMeteorProjectileData Parameters)
	{
		if (TargetedPlatforms.IsEmpty())
			FindTargetedPlatforms();
		Parameters.Projectile.TargetPlatform = TargetedPlatforms[0].Platform;
		if (SanctuaryBallistaHydraDevToggles::Draw::Meteor.IsEnabled())
			Debug::DrawDebugLine(Parameters.Projectile.TargetPlatform.ActorLocation + FVector::UpVector * 300, Parameters.Projectile.ActorLocation, LineColor = ColorDebug::Gray, Duration = MedallionHydraMeteorAttack::DebugDrawDuration);
		TargetedPlatforms.RemoveAt(0);
	}

	private void FindTargetedPlatforms()
	{
		// this is probably not performant at all but whatever. It's easy to rely on sorted arrays :shrug:

		// find all A or B platforms close to Zoe & Mio
		// then target from left to right

		TListedActors<ABallistaHydraSplinePlatform> ListedPlatforms;
		TArray<ABallistaHydraSplinePlatform> AvailablePlatforms = ListedPlatforms.GetArray();

		TArray<FMedallionHydraMeteorClosestPlatformTargetData> MioClosestPlatforms;
		TArray<FMedallionHydraMeteorClosestPlatformTargetData> ZoeClosestPlatforms;

		AHazePlayerCharacter Mio = Game::Mio;
		AHazePlayerCharacter Zoe = Game::Zoe;
		float MioDistance = BallistaRefs.Refs.Spline.Spline.GetClosestSplineDistanceToWorldLocation(Mio.ActorLocation);
		float ZoeDistance = BallistaRefs.Refs.Spline.Spline.GetClosestSplineDistanceToWorldLocation(Zoe.ActorLocation);
		FVector MioSplineOffset = Mio.ActorLocation - BallistaRefs.Refs.Spline.Spline.GetWorldLocationAtSplineDistance(MioDistance);
		FVector ZoeSplineOffset = Zoe.ActorLocation - BallistaRefs.Refs.Spline.Spline.GetWorldLocationAtSplineDistance(ZoeDistance);
		const float FutureSplineOffset = -2000;
		FVector FutureMioLocation = BallistaRefs.Refs.Spline.Spline.GetWorldLocationAtSplineDistance(Math::Clamp(MioDistance + FutureSplineOffset, 0.0, BallistaRefs.Refs.Spline.Spline.SplineLength)) + MioSplineOffset;
		FVector FutureZoeLocation = BallistaRefs.Refs.Spline.Spline.GetWorldLocationAtSplineDistance(Math::Clamp(ZoeDistance + FutureSplineOffset, 0.0, BallistaRefs.Refs.Spline.Spline.SplineLength)) + ZoeSplineOffset;

		if (SanctuaryBallistaHydraDevToggles::Draw::Meteor.IsEnabled())
		{
			Debug::DrawDebugSphere(FutureMioLocation, 200, 12, LineColor = Mio.GetPlayerUIColor(), Duration = MedallionHydraMeteorAttack::DebugDrawDuration);
			Debug::DrawDebugSphere(FutureZoeLocation, 200, 12, LineColor = Zoe.GetPlayerUIColor(), Duration = MedallionHydraMeteorAttack::DebugDrawDuration);
		}

		for (auto Platform : AvailablePlatforms)
		{
			{
				FMedallionHydraMeteorClosestPlatformTargetData Data;
				Data.Platform = Platform;
				Data.ComparePlayer = Mio;
				Data.TargetType = LastTargetType;
				Data.Distance = Platform.ActorLocation.Distance(FutureMioLocation);
				MioClosestPlatforms.Add(Data);
			}
			{
				FMedallionHydraMeteorClosestPlatformTargetData Data;
				Data.Platform = Platform;
				Data.ComparePlayer = Zoe;
				Data.TargetType = LastTargetType;
				Data.Distance = Platform.ActorLocation.Distance(FutureZoeLocation);
				ZoeClosestPlatforms.Add(Data);
			}
		}

		MioClosestPlatforms.Sort();
		ZoeClosestPlatforms.Sort();

		int iFoundPlatforms = 0;
		int iZoePlatforms = 0;
		int iMioPlatforms = 0;
		int Escape = 100;
		bool bCheckZoe = false;
		while (iFoundPlatforms < ProjectilesToSpawn && Escape >= 0)
		{
			FMedallionHydraMeteorClosestPlatformTargetData Data;
			if (bCheckZoe)
			{
				Data = ZoeClosestPlatforms[iZoePlatforms];
				iZoePlatforms++;
			}
			else
			{
				Data = MioClosestPlatforms[iMioPlatforms];
				iMioPlatforms++;
			}
			if (!HasTargetedPlatform(Data.Platform))
			{
				iFoundPlatforms++;
				FMedallionHydraMeteorLeftToRightPlatformTargetData TargetData;
				TargetData.Platform = Data.Platform;
				if (SanctuaryBallistaHydraDevToggles::Draw::Meteor.IsEnabled())
				{
					Debug::DrawDebugLine(Data.Platform.ActorLocation + FVector::UpVector * 300, Data.ComparePlayer.ActorLocation, LineColor = Data.ComparePlayer.GetPlayerUIColor(), Duration = MedallionHydraMeteorAttack::DebugDrawDuration);
					Debug::DrawDebugSphere(Data.Platform.ActorLocation + FVector::UpVector * 300, 100, 12, LineColor = Data.ComparePlayer.GetPlayerUIColor(), Duration = MedallionHydraMeteorAttack::DebugDrawDuration);
				}
				TargetedPlatforms.Add(TargetData);
				bCheckZoe = !bCheckZoe;
			}

			Escape--;
		}

		TargetedPlatforms.Sort();
	}

	private bool HasTargetedPlatform(ABallistaHydraSplinePlatform Platform) const
	{
		for (auto Data : TargetedPlatforms)
		{
			if (Data.Platform == Platform)
				return true;
		}
		return false;
	}

	UFUNCTION()
	private void Deactivate()
	{
		Hydra.MoveHeadPivotComp.Clear(this);
		bActive = false;
		MovementQueueComp.Empty();
	}

	UFUNCTION()
	private void PlayAttackAnimation()
	{
		if (!bActive)
			return;
		Hydra.OneshotAnimation(EFeatureTagMedallionHydra::MeteorFire);
		Hydra.ClearBlockLaunchProjectiles(this);
	}
};

struct FMedallionHydraMeteorProjectileData
{
	AMedallionHydraMeteorProjectile Projectile;
}

struct FMedallionHydraMeteorLeftToRightPlatformTargetData
{
	ABallistaHydraSplinePlatform Platform;

	int opCmp(const FMedallionHydraMeteorLeftToRightPlatformTargetData& Other) const
	{
		if (Platform.ActorLocation.Y > Other.Platform.ActorLocation.Y)
			return -1;
		else if (Platform.ActorLocation.Y < Other.Platform.ActorLocation.Y)
			return 1;
		return 0;
	}
}

struct FMedallionHydraMeteorClosestPlatformTargetData
{
	ABallistaHydraSplinePlatform Platform;
	AHazePlayerCharacter ComparePlayer;
	EBallistaHydraMeteorTargetType TargetType;
	float Distance;

	int opCmp(const FMedallionHydraMeteorClosestPlatformTargetData& Other) const
	{
		if (Platform.MeteorTargetType != Other.Platform.MeteorTargetType)
		{
			if (Platform.MeteorTargetType == TargetType)
				return -1;
			return 1;
		}

		return Distance < Other.Distance ? -1 : 1;
	}
}
