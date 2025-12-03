struct FSanctuaryCompanionAviationAssignToAttackDestinationActivationParams
{
	FVector PlayerLocation;
}

class USanctuaryCompanionAviationAssignToAttackDestinationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;
	USanctuaryCompanionAviationDestinationComponent DestinationComp;

	FVector CachedCenter;
	FTransform SwoopbackTarget;
	FTransform EntryTarget;

	FVector PlayerLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		DestinationComp = USanctuaryCompanionAviationDestinationComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationAssignToAttackDestinationActivationParams& Params) const
	{
		if (Player.IsPlayerDead())
			return false;

		if (AviationComp.HasDestination())
			return false;

		if (DestinationComp.bDevTriggerSwoopOutNormal)
		{
			Params.PlayerLocation = Owner.ActorLocation;
			return true;
		}

		if (!AviationComp.bIsRideReady)
			return false;

		if (!IsActioning(AviationComp.PromptRide.Action))
			return false;
		
		if (CompanionAviation::bUseLevelSequenceSwoop)
			return false;

		Params.PlayerLocation = Owner.ActorLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationAssignToAttackDestinationActivationParams Params)
	{
		DestinationComp.bDevTriggerSwoopOutNormal = false;
		PlayerLocation = Params.PlayerLocation;
		InfuseEssenceComp.ResetOrbs();
		AssignHydraAttackDestination();
	}

	private void AssignHydraAttackDestination()
	{
		AviationComp.UpdateCurrentSide();
		AviationComp.UpdateCurrentOctant();

		// YW:
		// After a lot of prototyping how we should "choose" our path to the hydra via different points and splines
		// We arrived at the conclusion we build the path using Runtime Splines instead

		TListedActors<ASanctuaryBossArenaManager> ArenaOrigoActor;
		check(ArenaOrigoActor.Num() == 1, "More or less than one ASanctuaryBossArenaManager found!");
		ASanctuaryBossArenaManager ArenaManager = ArenaOrigoActor[0];
		CachedCenter = ArenaManager.ActorLocation;

		BuildSwoopbackSpline();
		BuildEntrySpline();
		BuildToAttackSpline();
	}

	/*
	We slice up the hydra arena into quadrants and octants (aka slices of eight aka half a quad)
         , - ~ ~ ~ - ,
     , '               ' ,
   ,                       ,
  ,                         ,
 ,           HYDRA           ,
 ,             O             ,
 ,          X  .  X          ,
  ,      X     .     X      ,
   ,  X        .        X  ,
     ,         .        , '
       ' - , _ _ _ ,  '
	   LEFT          RIGHT
	OCTANT            OCTANT
		 PLAYER QUADRANT
	*/

	UFUNCTION()
	private void BuildSwoopbackSpline()
	{
		FSanctuaryCompanionAviationDestinationData Data;
		FVector UpwardsPoint = PlayerLocation;
		UpwardsPoint.Z += AviationComp.Settings.StartAviationImpulseReachAdditionalHeight;
		Data.RuntimeSpline.AddPoint(UpwardsPoint);

		FVector FurtherBack = UpwardsPoint - CachedCenter;
		FurtherBack = FurtherBack.GetSafeNormal() * AviationComp.Settings.SwoopbackAdditionalDistance;
		FurtherBack.Z = AviationComp.Settings.SwoopbackAdditionalStartHeight;
		FVector SwoopbackLocation = UpwardsPoint + FurtherBack;
		
		Data.RuntimeSpline.AddPoint(SwoopbackLocation);
		SwoopbackTarget = FTransform(FRotator::MakeFromXZ(FurtherBack.GetSafeNormal(), FVector::UpVector), SwoopbackLocation);

		Data.AviationState = EAviationState::SwoopingBack;
		AviationComp.AddDestination(Data);
	}

	UFUNCTION()
	private void BuildEntrySpline()
	{
		/*
				o o
				o   o
				,P- ~ Q ~ - ,
			, '   .   |       ' ,
		  ,    X   .  |      X    ,
		,        X  . |    X       ,
		,          X .|  X          ,
		,           HYDRA           ,
		,                           ,
		 ,                         ,
		  ,                       ,
		   ,                  , '
			 ' - , _ _ _ ,  '
		legend:
		X is quadrant slice
		| is octant slice
		Q is quadrant center
		P is for player
		o is the turning path we want to take towards center
		. represents SwoopbackTarget Forward is rotated from center ouwards    
		*/
		FSanctuaryCompanionAviationDestinationData Data;
		TArray<FVector> SplinePoints;

		// To do a right turn (clockwise) we need to offset with a LeftVector
		//        3
		//    2       4
		//  1     P     5

		// To do a left turn (counter clockwise) we need to offset with a RightVector
		//        3
		//    4       2
		//  5     P     1

		float TurningClockwiseSign = AviationComp.CurrentOctantSide == ESanctuaryArenaSideOctant::Right ? 1.0 : -1.0;
		FVector OffsetDirection = SwoopbackTarget.Rotation.RightVector * -TurningClockwiseSign;
		const float Radius = AviationComp.Settings.SwoopbackRadius;
		FVector First = OffsetDirection * Radius;
		FVector Second = (OffsetDirection + SwoopbackTarget.Rotation.ForwardVector).GetSafeNormal() * Radius;
		FVector Third = SwoopbackTarget.Rotation.ForwardVector * Radius;
		FVector Fourth = (-OffsetDirection + SwoopbackTarget.Rotation.ForwardVector).GetSafeNormal() * Radius;
		FVector Fifth = -OffsetDirection * Radius;

		// We need to offset our points towards Quadrant center
		// so we should ideally "be" at our first point when we enter this spline
		FVector InwardsOffset = -OffsetDirection * Radius;
		FVector TotalLocation = SwoopbackTarget.Location + InwardsOffset;
		float AddedHeightOffset = AviationComp.Settings.SwoopbackAdditionalEndHeight * 0.25; // We spread height offset over all points except "First"
		SplinePoints.Add(TotalLocation + First);
		SplinePoints.Add(TotalLocation + Second + FVector::UpVector * AddedHeightOffset);
		SplinePoints.Add(TotalLocation + Third  + FVector::UpVector * AddedHeightOffset * 2);
		SplinePoints.Add(TotalLocation + Fourth + FVector::UpVector * AddedHeightOffset * 3);
		SplinePoints.Add(TotalLocation + Fifth  + FVector::UpVector * AddedHeightOffset * 4);

		FVector ExitPointToCenter = CachedCenter - SplinePoints.Last();
		ExitPointToCenter.Z = 0.0;
		FVector Sixth = Fifth + ExitPointToCenter.GetSafeNormal() * 400.0;
		SplinePoints.Add(TotalLocation + Sixth  + FVector::UpVector * AddedHeightOffset * 4);
		
		Data.RuntimeSpline.SetPoints(SplinePoints);
		EntryTarget = FTransform(FRotator::MakeFromXZ(ExitPointToCenter.GetSafeNormal(), FVector::UpVector), SplinePoints.Last());
		Data.RuntimeSpline.SetCustomEnterTangentPoint(SwoopbackTarget.Rotation.ForwardVector);
		Data.RuntimeSpline.SetCustomExitTangentPoint(EntryTarget.Rotation.ForwardVector);
		Data.AviationState = EAviationState::Entry;
		AviationComp.AddDestination(Data);
	}

	UFUNCTION()
	private void BuildToAttackSpline()
	{
		FSanctuaryCompanionAviationDestinationData Data;
		
		TArray<FVector> SplinePoints;
		SplinePoints.Add(EntryTarget.Location);

		FVector TargetLocation = CachedCenter;
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		for (auto Head : Hydras.Single.HydraHeads)
		{
			if (Head.TargetPlayer == Player)
			{
				TargetLocation.X = Head.ActorLocation.X;
				TargetLocation.Y = Head.ActorLocation.Y;
				break;
			}
		}

		FVector ToCenter = TargetLocation - EntryTarget.Location;
		ToCenter.Z = 0.0;
		float ToCenterLength = ToCenter.Size();
		float ToAttackLength = Math::Clamp(ToCenterLength - AviationComp.Settings.ToAttackDistanceStopBeforeHydra, 10.0, 10000000);
		ToCenter = ToCenter.GetSafeNormal() * ToAttackLength;
		FVector ToAttackEndLocation = EntryTarget.Location + ToCenter;
		SplinePoints.Add(ToAttackEndLocation);

		// Data.RuntimeSpline.SetCustomEnterTangentPoint(EntryTarget.Rotation.ForwardVector);
		Data.RuntimeSpline.SetPoints(SplinePoints);
		Data.AviationState = EAviationState::ToAttack;
		AviationComp.AddDestination(Data);
	}
};