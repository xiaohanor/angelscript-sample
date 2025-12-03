event void FSkylineJetpackBillboardDestroyedSignature();

class ASkylineJetpackCombatZoneManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegistrationComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipSlingAutoAimComponent WhipAutoAim;
	default WhipAutoAim.bWidgetFollowsAutoAimPoint = true;

	UPROPERTY(DefaultComponent)
	UJetpackBillboardHealthBarComponent HealthBarComp;

	UPROPERTY(EditAnywhere)
	int NumExplodedZonesToDestroy = 6;

	UPROPERTY(Transient, BlueprintReadOnly)
	FSkylineJetpackBillboardDestroyedSignature OnBillboardDestroyed;

	AJetpackCombatSign FauxPhysicsRoot;
	TArray<ASkylineJetpackCombatZone> BillboardZones;
	TArray<ASkylineJetpackCombatZone> IntactZones;

	FHazeShapeSettings BillboardShape;
	default BillboardShape.Type = EHazeShapeType::Box;

	UEnforcerHoveringSettings Settings;

	ARespawnPoint BillboardRespawnPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UEnforcerHoveringSettings::GetSettings(this); 

		// Build box containing billboard zones
		BillboardZones = TListedActors<ASkylineJetpackCombatZone>().Array;
		if (!ensure(BillboardZones.Num() > 0))
			return;
		
		IntactZones = BillboardZones;

		// Calculate billboard bounds
		FTransform StartTransform = BillboardZones[0].ActorTransform;
		StartTransform.Scale3D = FVector::OneVector;
		float MaxWidth = -BIG_NUMBER;
		float MinWidth = BIG_NUMBER;
		float MaxHeight = -BIG_NUMBER;
		float MinHeight = BIG_NUMBER;
		for (ASkylineJetpackCombatZone Zone : BillboardZones)
		{
			// Assume all zones have the same rotation
			check(Zone.ActorQuat.Equals(StartTransform.Rotation));
			FBox Bounds = Zone.GetActorLocalBoundingBox(false);
			FVector ZoneLoc = StartTransform.InverseTransformPosition(Zone.ActorLocation); 
			MaxWidth = Math::Max(MaxWidth, Bounds.Max.X + ZoneLoc.X);
			MinWidth = Math::Min(MinWidth, Bounds.Min.X + ZoneLoc.X);
			MaxHeight = Math::Max(MaxHeight, Bounds.Max.Y + ZoneLoc.Y);
			MinHeight = Math::Min(MinHeight, Bounds.Min.Y + ZoneLoc.Y);
		}
		FVector Center;
		Center.X = (MaxWidth + MinWidth) * 0.5;
		Center.Y = (MaxHeight + MinHeight) * 0.5;
		Center.Z = -Settings.BillboardDetectionSizePadding.Z * 0.5;
		ActorLocation = StartTransform.TransformPosition(Center);
		ActorRotation = StartTransform.Rotator();		
		BillboardShape.BoxExtents = FVector((MaxWidth - MinWidth) * 0.5 + Settings.BillboardDetectionSizePadding.X, 
											(MaxHeight - MinHeight) * 0.5 + Settings.BillboardDetectionSizePadding.Y, 
											Settings.BillboardDetectionSizePadding.Z);

		WhipAutoAim.TargetShape.Type = EHazeShapeType::Box;
		WhipAutoAim.TargetShape.BoxExtents = BillboardShape.BoxExtents - Settings.BillboardDetectionSizePadding + FVector(0.0, 0.0, 10.0);

		for (ASkylineJetpackCombatZone Zone : BillboardZones)
		{
			Zone.OnExplode.AddUFunction(this, n"OnZoneExplode");
			Zone.OnTelegraphExplosion.AddUFunction(this, n"OnZoneTelegraphExplosion");
		}

		// HACK: We don't have a BP class for this yet, get assets from first zone
		HealthBarComp.Desc = BillboardZones[0].HealthBarDesc;
		HealthBarComp.HealthBarWidgetClass = BillboardZones[0].HealthBarWidgetClass;

		FauxPhysicsRoot = TListedActors<AJetpackCombatSign>().GetSingle();
		AttachToActor(FauxPhysicsRoot, NAME_None, EAttachmentRule::KeepWorld);

		// Find first respawn point at billboard. This will always be placed at an intact zone.
		for (ARespawnPoint RespawnPoint : TListedActors<ARespawnPoint>())
		{
			if (RespawnPoint.bCanMioUse == false)
				continue;
			FVector BillboardLoc = LineBillboardPlaneIntersection(RespawnPoint.ActorLocation, -RespawnPoint.ActorUpVector);
			if (Math::Abs(RespawnPoint.ActorUpVector.DotProduct(BillboardLoc - RespawnPoint.ActorLocation)) > 400.0)
				continue; // Far above or below respan point
			if (!IsAtBillboard(BillboardLoc))
				continue;
			BillboardRespawnPoint = RespawnPoint;
			break;
		}
	}

	UFUNCTION()
	private void OnZoneTelegraphExplosion(ASkylineJetpackCombatZone Zone)
	{
		IntactZones.Remove(Zone);
		MoveRespawnPointToIntactZone(Zone);
	}

	UFUNCTION()
	private void OnZoneExplode(ASkylineJetpackCombatZone Zone)
	{
		IntactZones.Remove(Zone);
		int NumExplodedZones = BillboardZones.Num() - IntactZones.Num();
		HealthBarComp.OnTakeDamage(float(NumExplodedZonesToDestroy - NumExplodedZones) / float(NumExplodedZonesToDestroy - 1));
		if (NumExplodedZones >= NumExplodedZonesToDestroy)
			OnBillboardDestroyed.Broadcast();	
		MoveRespawnPointToIntactZone(Zone);
	}

	void MoveRespawnPointToIntactZone(ASkylineJetpackCombatZone DestroyedZone)
	{
		if (BillboardRespawnPoint == nullptr)
			return;
		FVector RespawnLocalLoc = DestroyedZone.ActorTransform.InverseTransformPosition(BillboardRespawnPoint.ActorLocation);
		if (!DestroyedZone.GetActorLocalBoundingBox(false).IsInside(RespawnLocalLoc))
			return; // Outside zone, all good
		int iRndIntactZone = Math::RandRange(0, IntactZones.Num() - 1);
		ASkylineJetpackCombatZone IntactZone = IntactZones[iRndIntactZone];
		BillboardRespawnPoint.SetActorLocation(IntactZone.ActorTransform.TransformPosition(RespawnLocalLoc));			
	}

	bool IsAtBillboard(FVector Loc) const
	{
		return BillboardShape.IsPointInside(ActorTransform, Loc);
	}

	bool HasRayBillboardIntersection(FVector StartLoc, FVector Direction) const
	{
		FVector LocalStart = ActorTransform.InverseTransformPosition(StartLoc);
		FVector LocalEnd = LocalStart + ActorTransform.InverseTransformVector(Direction) * (LocalStart.Size() + BillboardShape.BoxExtents.Size() * 2.0 + 100.0);
		FBox BillboardBox = FBox(-BillboardShape.BoxExtents, BillboardShape.BoxExtents);
		return Math::LineBoxIntersection(BillboardBox, LocalStart, LocalEnd);
	}

	FVector LineBillboardPlaneIntersection(FVector StartLoc, FVector Direction) const
	{
		return Math::LinePlaneIntersection(StartLoc, StartLoc + Direction, ActorLocation, ActorUpVector);
	}

	ASkylineJetpackCombatZone GetNearestIntactBillboardZone(FVector Location) const
	{
		ASkylineJetpackCombatZone NearestZone = nullptr;
		float MinDistSqr = BIG_NUMBER;
		for (ASkylineJetpackCombatZone Zone : IntactZones)
		{	
			if (!IsValid(Zone))
				continue;
			float DistSqr = Location.DistSquared(Zone.ActorLocation);
			if (DistSqr > MinDistSqr)
				continue;
			MinDistSqr = DistSqr;
			NearestZone = Zone;
		}
		return NearestZone;
	}

	ASkylineJetpackCombatZone GetNearestUnoccupiedBillboardZone(FVector Location) const
	{
		ASkylineJetpackCombatZone NearestZone = nullptr;
		float MinDistSqr = BIG_NUMBER;
		for (ASkylineJetpackCombatZone Zone : IntactZones)
		{	
			if (!IsValid(Zone))
				continue;
			if (Zone.CurrentlyOccupiedBy != nullptr)
				continue;
			float DistSqr = Location.DistSquared(Zone.ActorLocation);
			if (DistSqr > MinDistSqr)
				continue;
			MinDistSqr = DistSqr;
			NearestZone = Zone;
		}
		return NearestZone;
	}

	UFUNCTION(BlueprintPure)
	TArray<ASkylineJetpackCombatZone> GetAllJetpackCombatZone() const
	{
		return BillboardZones;
	}

	UFUNCTION(BlueprintPure)
	TArray<ASkylineJetpackCombatZoneGround> GetAllJetpackCombatZoneGround() const
	{
		return TListedActors<ASkylineJetpackCombatZoneGround>().Array;
	}

	UFUNCTION(DevFunction)
	void ShowBillboardHealthBar()
	{
		HealthBarComp.Initialize(NumExplodedZonesToDestroy - 1);
		HealthBarComp.ShowHealthBar();
	}
}

