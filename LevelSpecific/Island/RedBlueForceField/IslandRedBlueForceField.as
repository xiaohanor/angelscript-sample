event void FIslandRedBlueForceFieldOnChangeType(EIslandRedBlueShieldType NewType);

class UIslandRedBlueForceFieldVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandRedBlueForceFieldVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ForceField = Cast<AIslandRedBlueForceField>(Component.Owner);

		if(!ForceField.bIsSphereForceField)
			DrawForceFieldNormal(Component);
	}

	private void DrawForceFieldNormal(const UActorComponent Component)
	{
		const float PlaneExtents = 50.0;
		const float ArrowLength = 200.0;
		const float ArrowSize = 20.0;
		const float LineThickness = 4.0;
		const float ArrowLineThickness = 4.0;
		const FLinearColor Color = FLinearColor::Red;

		const FTransform ActorTransform = Component.Owner.ActorTransform;
		const FVector Forward = ActorTransform.Rotation.ForwardVector;
		const FVector Right = ActorTransform.Rotation.RightVector;
		const FVector Up = ActorTransform.Rotation.UpVector;

		const FVector Origin = ActorTransform.Location;
		const FVector ArrowEnd = ActorTransform.Location + Forward * ArrowLength;

		DrawArrow(Origin, ArrowEnd, Color, ArrowSize, ArrowLineThickness);

		const FVector PlanePoint1 = Origin - Up * PlaneExtents - Right * PlaneExtents;
		const FVector PlanePoint2 = Origin + Up * PlaneExtents - Right * PlaneExtents;
		const FVector PlanePoint3 = Origin + Up * PlaneExtents + Right * PlaneExtents;
		const FVector PlanePoint4 = Origin - Up * PlaneExtents + Right * PlaneExtents;
		DrawLine(PlanePoint1, PlanePoint2, Color, LineThickness);
		DrawLine(PlanePoint2, PlanePoint3, Color, LineThickness);
		DrawLine(PlanePoint3, PlanePoint4, Color, LineThickness);
		DrawLine(PlanePoint4, PlanePoint1, Color, LineThickness);
		DrawWorldString("Normal", ArrowEnd, Color);
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandRedBlueForceFieldVisualizerComponent : UActorComponent
{

}

enum EIslandRedBlueForceFieldSphereType
{
	Sphere,
	Dome
}

struct FIslandForceFieldHoleDataArray
{
	FIslandForceFieldHoleDataArray(AIslandRedBlueForceField In_ForceField)
	{
		ForceField = In_ForceField;
	}

	TArray<FIslandForceFieldHoleData> HoleData;
	AIslandRedBlueForceField ForceField;

	// Will return true if the given circle is inside one or several holes.
	bool IsCircleInsideHoles(FVector CircleWorldLocation, float CircleRadius)
	{
		for(auto& Data : HoleData)
		{
			if (!Data.bIsValidHole)
				continue;
			if(IsCircleInsideHole(Data, CircleWorldLocation, CircleRadius))
				return true;
		}

		return false;
	}

	bool IsCircleInsideHole(const FIslandForceFieldHoleData& Data, FVector CircleWorldLocation, float CircleRadius)
	{
		if(CircleRadius >= Data.HoleRadius)
			return false;

		return CircleWorldLocation.DistSquared(ForceField.GetHoleWorldLocation(Data)) < Math::Square(Data.HoleRadius - CircleRadius);
	}

	bool IsPointInsideHole(const FIslandForceFieldHoleData& Data, FVector PointWorldLocation)
	{
		return IsCircleInsideHole(Data, PointWorldLocation, 0.0);
	}

	// Will return true if the given point is inside one or several holes.
	bool IsPointInsideHoles(FVector PointWorldLocation)
	{
		return IsCircleInsideHoles(PointWorldLocation, 0.0);
	}

	bool IsShapeInsideHoles(FCollisionShape Shape, FTransform ShapeTransform, float AdditionalCollisionShapeTolerance, bool bDebug = false)
	{
		TArray<FVector> PointsToCheck;

		if(ForceField.bIsSphereForceField)
			GetPointsToCheckForSphere(Shape, ShapeTransform, PointsToCheck, AdditionalCollisionShapeTolerance);
		else
			GetPointsToCheckForPlane(Shape, ShapeTransform, PointsToCheck, AdditionalCollisionShapeTolerance);

		if(bDebug)
		{
			for(FVector Point : PointsToCheck)
			{
				bool bIsInside = IsPointInsideHoles(Point);
				Debug::DrawDebugPoint(Point, 5.0, bIsInside ? FLinearColor::Green : FLinearColor::Red);
			}
		}

		for(FVector Point : PointsToCheck)
		{
			if(!IsPointInsideHoles(Point))
				return false;
		}

		return true;
	}

	void GetPointsToCheckForPlane(FCollisionShape Shape, FTransform ShapeTransform, TArray<FVector>& PointsToCheck, float AdditionalCollisionShapeTolerance)
	{
		const FPlane Plane = FPlane(ForceField.ActorLocation, ForceField.ActorForwardVector);
		const FVector ProjectedShapeCenterLocation = Math::RayPlaneIntersection(ShapeTransform.Location, ForceField.ActorForwardVector, Plane);

		float CollisionShapeTolerance = ForceField.CollisionShapeTolerance + AdditionalCollisionShapeTolerance;

		if(Shape.IsCapsule())
		{
			float HalfHeight = Shape.CapsuleHalfHeight - Math::Min(CollisionShapeTolerance * 2.0, Shape.CapsuleHalfHeight);
			// To support alternate player world up's and rotated force fields, this will squish the capsule down the more out of alignment the force field/player's up are
			HalfHeight *= ForceField.ActorUpVector.DotProduct(ShapeTransform.Rotation.UpVector);
			const float Radius = Shape.CapsuleRadius - Math::Min(CollisionShapeTolerance, Shape.CapsuleRadius);

			const FVector Up = ForceField.ActorUpVector;
			const FVector Right = ForceField.ActorRightVector;

			const FVector CapsuleCenter = ProjectedShapeCenterLocation;
			const FVector CapsuleRoot = CapsuleCenter - Up * HalfHeight;
			const FVector CapsuleTop = CapsuleCenter + Up * HalfHeight;
			const FVector BottomSphereCenter = CapsuleRoot + Up * Radius;
			const FVector TopSphereCenter = CapsuleTop - Up * Radius;

			// Pick points from player capsule that silhouette the capsule on the force field and check if they are inside holes, if yes, ignore collision
			PointsToCheck.Add(CapsuleRoot); // Player root
			PointsToCheck.Add(BottomSphereCenter); // Player bottom sphere center
			PointsToCheck.Add(CapsuleCenter); // Player center
			PointsToCheck.Add(TopSphereCenter); // Player top sphere center
			PointsToCheck.Add(CapsuleTop); // Player top
			PointsToCheck.Add(BottomSphereCenter + Right * Radius); // Bottom right
			PointsToCheck.Add(BottomSphereCenter - Right * Radius); // Bottom left
			PointsToCheck.Add(CapsuleCenter + Right * Radius); // Center right
			PointsToCheck.Add(CapsuleCenter - Right * Radius); // Center left
			PointsToCheck.Add(TopSphereCenter + Right * Radius); // Top right
			PointsToCheck.Add(TopSphereCenter - Right * Radius); // Top left
		}
		else if(Shape.IsSphere())
		{
			const float Radius = Shape.SphereRadius - Math::Min(CollisionShapeTolerance, Shape.SphereRadius);

			const FVector Up = ForceField.ActorUpVector;
			const FVector Right = ForceField.ActorRightVector;

			const FVector SphereCenter = ProjectedShapeCenterLocation;

			PointsToCheck.Add(SphereCenter); // Sphere center
			PointsToCheck.Add(SphereCenter + Up * Radius); // Sphere top
			PointsToCheck.Add(SphereCenter - Up * Radius); // Sphere bottom
			PointsToCheck.Add(SphereCenter + Right * Radius); // Sphere right
			PointsToCheck.Add(SphereCenter - Right * Radius); // Sphere left
		}
		else
			devError("This collision shape is not supported for use with force fields");
	}

	void GetPointsToCheckForSphere(FCollisionShape Shape, FTransform ShapeTransform, TArray<FVector>& PointsToCheck, float AdditionalCollisionShapeTolerance)
	{
		const FVector Up = ShapeTransform.Rotation.UpVector;
		const FVector SphereToShapeDir = (ShapeTransform.Location - ForceField.ActorLocation).GetSafeNormal2D();
		const FVector Right = Up.CrossProduct(SphereToShapeDir);
		const FVector Forward = -Up.CrossProduct(Right);

		float CollisionShapeTolerance = ForceField.CollisionShapeTolerance + AdditionalCollisionShapeTolerance;

		if(Shape.IsCapsule())
		{
			float HalfHeight = Shape.CapsuleHalfHeight - Math::Min(CollisionShapeTolerance * 2.0, Shape.CapsuleHalfHeight);
			const float Radius = Shape.CapsuleRadius - Math::Min(CollisionShapeTolerance, Shape.CapsuleRadius);

			const FVector CapsuleCenter = ShapeTransform.Location;
			const FVector CapsuleRoot = CapsuleCenter - Up * HalfHeight;
			const FVector CapsuleTop = CapsuleCenter + Up * HalfHeight;
			const FVector BottomSphereCenter = CapsuleRoot + Up * Radius;
			const FVector TopSphereCenter = CapsuleTop - Up * Radius;

			// Pick points from player capsule in world space, these will then be projected on the sphere
			PointsToCheck.Add(CapsuleRoot); // Player root
			PointsToCheck.Add(BottomSphereCenter); // Player bottom sphere center
			PointsToCheck.Add(CapsuleCenter); // Player center
			PointsToCheck.Add(TopSphereCenter); // Player top sphere center
			PointsToCheck.Add(CapsuleTop); // Player top
			PointsToCheck.Add(BottomSphereCenter + Right * Radius); // Bottom right
			PointsToCheck.Add(BottomSphereCenter - Right * Radius); // Bottom left
			PointsToCheck.Add(CapsuleCenter + Right * Radius); // Center right
			PointsToCheck.Add(CapsuleCenter - Right * Radius); // Center left
			PointsToCheck.Add(TopSphereCenter + Right * Radius); // Top right
			PointsToCheck.Add(TopSphereCenter - Right * Radius); // Top left
			PointsToCheck.Add(BottomSphereCenter + Forward * Radius); // Bottom forward
			PointsToCheck.Add(BottomSphereCenter - Forward * Radius); // Bottom back
			PointsToCheck.Add(CapsuleCenter + Forward * Radius); // Center forward
			PointsToCheck.Add(CapsuleCenter - Forward * Radius); // Center back
			PointsToCheck.Add(TopSphereCenter + Forward * Radius); // Top forward
			PointsToCheck.Add(TopSphereCenter - Forward * Radius); // Top back
		}
		else if(Shape.IsSphere())
		{
			const float Radius = Shape.SphereRadius - Math::Min(CollisionShapeTolerance, Shape.SphereRadius);

			const FVector SphereCenter = ShapeTransform.Location;

			PointsToCheck.Add(SphereCenter); // Sphere center
			PointsToCheck.Add(SphereCenter + Up * Radius); // Sphere top
			PointsToCheck.Add(SphereCenter - Up * Radius); // Sphere bottom
			PointsToCheck.Add(SphereCenter + Right * Radius); // Sphere right
			PointsToCheck.Add(SphereCenter - Right * Radius); // Sphere left
			PointsToCheck.Add(SphereCenter + Forward * Radius); // Sphere forward
			PointsToCheck.Add(SphereCenter - Forward * Radius); // Sphere back
		}
		else
			devError("This collision shape is not supported for use with force fields");


		const FVector SphereCenterToShapeCenterDirection = (ShapeTransform.Location - ForceField.ActorLocation).GetSafeNormal();
		for(int i = 0; i < PointsToCheck.Num(); i++)
		{
			FVector IntersectionCheckStart = PointsToCheck[i].PointPlaneProject(ForceField.ActorLocation, SphereCenterToShapeCenterDirection);
			FVector IntersectionCheckEnd = IntersectionCheckStart + SphereCenterToShapeCenterDirection * (ForceField.SphereRadius + 0.125);

			FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(IntersectionCheckStart, IntersectionCheckEnd, ForceField.ActorLocation, ForceField.SphereRadius);
			devCheck(Intersection.IntersectionCount == 1, "This shouldn't happen, why did it?");
			PointsToCheck[i] = Intersection.MinIntersection;
		}
	}
} 

struct FIslandForceFieldHoleData
{
	int MaterialParameterIndex;
	FVector HoleRelativeLocation;
	float MaxHoleRadius;
	float HoleRadius;
	float TimeOfShot;
	int HoleIndex = -1;
	uint HoleCreatedFrame;
	bool bHasStartedShrinking = false;
	bool bHasCalledAudio_OnHoleAlmostFullyClosed = false;

	AHazePlayerCharacter GrenadeOwner = nullptr;

	/**
	 * Whether this hole is currently valid or not.
	 * Invalid holes should be ignored and pretended they don't exist.
	 * 
	 * Invalid holes can happen if a force field changes color. Because of networking, we
	 * keep holes that are from the wrong player, but just ignore their existence.
	 * If the force field ever changes its color back to the right player, we consider the hole again.
	 */
	bool bIsValidHole = false;
}

class AIslandRedBlueForceField : AHazeActor
{
	access ReadOnly = private, * (readonly);
	access PunchotronHack = private, UIslandPunchotronElevatorFallThroughHoleCapability;

	// Tick last because we want movement and stuff to happen before (important for movable force fields)
	default TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent WallMesh_FrontPlane;
	default WallMesh_FrontPlane.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = "WallMesh_FrontPlane")
	UStaticMeshComponent CollisionMesh;
	default CollisionMesh.RelativeScale3D = FVector(1.0, 1.0, 0.01);
	default CollisionMesh.bHiddenInGame = true;
	default CollisionMesh.RemoveTag(ComponentTags::WallScrambleable);
	default CollisionMesh.RemoveTag(ComponentTags::WallRunnable);
	default CollisionMesh.RemoveTag(ComponentTags::LedgeGrabbable);
	default CollisionMesh.RemoveTag(ComponentTags::LedgeRunnable);
	default CollisionMesh.RemoveTag(ComponentTags::LedgeClimbable);
	default CollisionMesh.bBlockCollisionOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UIslandRedBlueImpactResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = "Root", ShowOnActor)
	UIslandRedBlueStickyGrenadeResponseComponent StickyGrenadeResponseComp;
	default StickyGrenadeResponseComp.bCanImpactMultipleTimesPerDetonation = true;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldStateComponent ForceFieldStateComp;
	default ForceFieldStateComp.bForceFieldIsOnEnemy = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly, BlueprintHidden)
	FLinearColor RedForceFieldColor = FLinearColor(10, 0.025, 0, 1);

	UPROPERTY(EditDefaultsOnly, BlueprintHidden)
	FLinearColor BlueForceFieldColor = FLinearColor(0, 2, 4, 1);

	UPROPERTY(EditDefaultsOnly, BlueprintHidden)
	FLinearColor BothForceFieldColor = FLinearColor(6, 1.43, 5.5, 1);

	UPROPERTY(EditDefaultsOnly, BlueprintHidden)
	bool bIsSphereForceField = false;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bIsSphereForceField", EditConditionHides))
	EIslandRedBlueForceFieldSphereType SphereType;

	/* The force field will swap colors if both players are within a spherical force field that has no holes, are the opposite color from the player inside and has this bool set to true */
	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bIsSphereForceField", EditConditionHides))
	bool bSoftLockProtection = false;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bIsSphereForceField && bSoftLockProtection", EditConditionHides))
	TArray<TSoftObjectPtr<AIslandRedBlueForceField>> SoftLockLinkedForceFields;

	UPROPERTY(EditAnywhere, BlueprintHidden, Category = "Grenade Response Component")
	bool bAutomaticallySetShapeBasedOnForceFieldBounds = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	access:ReadOnly EIslandRedBlueShieldType ForceFieldType = EIslandRedBlueShieldType::Both;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInterface SourceMaterial;

	UPROPERTY(NotVisible, BlueprintHidden)
	UMaterialInstanceDynamic DynMatFront;

	UPROPERTY(EditAnywhere, BlueprintHidden)
	private bool bActive = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bDebugPointsOnPlayerCollision = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bDebugHoles = false;

	// If true, response components will be triggered if they have a clear line of sight with a grenade through a force field hole
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bAllowStickyGrenadesToDetonateThroughHoles = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bBulletsShouldReflectOnSurface = true;

	/* The x axis is time in seconds, y: 0 means 0 shrink speed, y: 1 means BulletHoleMaxShrinkSpeed */
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FRuntimeFloatCurve BulletHoleShrinkSpeedCurve;
	default BulletHoleShrinkSpeedCurve.AddDefaultKey(0.0, 1.0);
	default BulletHoleShrinkSpeedCurve.AddDefaultKey(1.0, 1.0);

	/* How much radius will be lost per second */
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float BulletHoleMaxShrinkSpeed = 160.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float BulletHoleDelayBeforeShrinking = 0.0;

	/* When checking if player (and other actors with collision comp) should be able to pass through force field, the actor's collision extents will be subtracted with this to tolerate pass through even if capsule overlaps force field slightly */
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float CollisionShapeTolerance = 15.0;

	UPROPERTY()
	FIslandRedBlueForceFieldOnChangeType OnChangeForceFieldType;

	FIslandForceFieldHoleDataArray HoleDataArray;

	// Number that gets bumped whenever the forcefield have potentially changed.
	// This allows detecting when the force field has _not_ changed for performance reasons.
	uint64 ForceFieldChangeId = 1;

	private TArray<int> FreeMaterialParameterIndices;
	private TArray<UHazeMovementComponent> CollisionIgnoringMoveComps;
	private UIslandRedBlueForceFieldCollisionContainerComponent CollisionContainerComp;

	UPROPERTY()
	FHazeTimeLike ActivationAnimation;	
	default ActivationAnimation.Duration = 0.3;
	default ActivationAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ActivationAnimation.Curve.AddDefaultKey(0.3, 1.0);

	UPROPERTY(EditAnywhere)
	TArray<AActor> NearbyEffectActors;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	bool EdgeGlowUseVertexColor = false;
	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Tiling = 1.0;
	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Intensity = 1.0;
	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Fresnel = 1.0;
	UPROPERTY(EditAnywhere, Category = "Visuals")
	bool UseObjectScale = true;

	int WallChangeTarget = 0;
	float WallChange = 0;

	UPROPERTY(NotVisible, BlueprintHidden)
	FLinearColor TargetWallColor;

	UPROPERTY(NotVisible, BlueprintHidden)
	FLinearColor WallColor;

	bool bInsidePlayerIsSoftLocked = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DynMatFront = WallMesh_FrontPlane.CreateDynamicMaterialInstance(0, SourceMaterial, n"None");

		// Doing this since there was a bug where tag overrides on the BP was not propogated to instances.
		auto CDO = Cast<AIslandRedBlueForceField>(AIslandRedBlueForceField.DefaultObject);
		Editor::CopyAllComponentTags(CDO.CollisionMesh, CollisionMesh);

		UpdateMaterialColor(true);
		UpdateSphereMesh();

		if(bAutomaticallySetShapeBasedOnForceFieldBounds)
		{
			FBox Box = CollisionMesh.GetBoundingBoxRelativeToOwner();

			if(bIsSphereForceField)
			{
				StickyGrenadeResponseComp.Shape = FHazeShapeSettings::MakeSphere(Box.Extent.X);
			}
			else
			{
				StickyGrenadeResponseComp.Shape = FHazeShapeSettings::MakeBox(Box.Extent);
				StickyGrenadeResponseComp.WorldLocation = ActorTransform.TransformPosition(Box.Center);
			}
		}

		StickyGrenadeResponseComp.bTriggerForBluePlayer = ForceFieldType != EIslandRedBlueShieldType::Red;
		StickyGrenadeResponseComp.bTriggerForRedPlayer = ForceFieldType != EIslandRedBlueShieldType::Blue;

		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"EdgeGlowVertexColor"), EdgeGlowUseVertexColor ? 1 : 0);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"Tiling"), Tiling);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"Intensity"), Intensity);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"Fresnel"), Fresnel);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"UseObjectScale"), UseObjectScale ? 1 : 0);
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HoleDataArray = FIslandForceFieldHoleDataArray(this);
		SetCorrectControlSide();

		ImpactComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		StickyGrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnDetonated");
		StickyGrenadeResponseComp.OnAttached.AddUFunction(this, n"OnAttached");
		
		for(int i = 0; i < 10; i++)
		{
			FreeMaterialParameterIndices.Add(i);
		}

		CollisionContainerComp = UIslandRedBlueForceFieldCollisionContainerComponent::GetOrCreate(Game::Mio);
		RegisterEvents();
		
		ActivationAnimation.BindUpdate(this, n"ActivationAnimationUpdate");
		ActivationAnimation.BindFinished(this, n"ActivationAnimationFinished");
		if(!bActive)
		{
			DisableForceField();
		}

		EIslandForceFieldType Type = EIslandForceFieldType::Both;
		if(ForceFieldType == EIslandRedBlueShieldType::Red)
			Type = EIslandForceFieldType::Red;
		else if(ForceFieldType == EIslandRedBlueShieldType::Blue)
			Type = EIslandForceFieldType::Blue;
		else
			Type = EIslandForceFieldType::Both;
		
		ForceFieldStateComp.SetCurrentForceFieldType(Type);

#if TEST
		UTemporalLogTransformLoggerComponent::Create(this);
		UIslandRedBlueForceFieldHoleLoggerComponent::Create(this);
#endif
		AttachLocationLocal = FVector::OneVector * 9999999;
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"EdgeGlowVertexColor"), EdgeGlowUseVertexColor ? 1 : 0);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"Tiling"), Tiling);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"Intensity"), Intensity);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"Fresnel"), Fresnel);
		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(n"UseObjectScale"), UseObjectScale ? 1 : 0);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnregisterEvents();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		RegisterEvents();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		UnregisterEvents();
		ClearAllCollisionIgnoringMoveComps();
	}

	void RegisterEvents()
	{
		CollisionContainerComp.OnUnregisterMovementComponent.AddUFunction(this, n"OnUnregisterMoveComp");
	}

	void UnregisterEvents()
	{
		CollisionContainerComp.OnUnregisterMovementComponent.Unbind(this, n"OnUnregisterMoveComp");
	}

	UFUNCTION()
	access:PunchotronHack // Remove any Elevator Punchotron who made it to terra firma.
	void OnUnregisterMoveComp(UHazeMovementComponent MoveComp)
	{
		if(!CollisionIgnoringMoveComps.Contains(MoveComp))
			return;

		MoveComp.RemoveMovementIgnoresActor(this);
		CollisionIgnoringMoveComps.RemoveSingleSwap(MoveComp);
	}

	UFUNCTION()
	void SetForceFieldType(EIslandRedBlueShieldType NewForceFieldType)
	{
		ForceFieldType = NewForceFieldType;

		SetCorrectControlSide();
		UpdateMaterialColor();

		StickyGrenadeResponseComp.bTriggerForBluePlayer = ForceFieldType != EIslandRedBlueShieldType::Red;
		StickyGrenadeResponseComp.bTriggerForRedPlayer = ForceFieldType != EIslandRedBlueShieldType::Blue;

		EIslandForceFieldType Type = EIslandForceFieldType::Both;
		if(ForceFieldType == EIslandRedBlueShieldType::Red)
			Type = EIslandForceFieldType::Red;
		else if(ForceFieldType == EIslandRedBlueShieldType::Blue)
			Type = EIslandForceFieldType::Blue;
		else
			Type = EIslandForceFieldType::Both;
		
		ForceFieldStateComp.SetCurrentForceFieldType(Type);
		OnChangeForceFieldType.Broadcast(ForceFieldType);
	}

	private void SetCorrectControlSide()
	{
		if(ForceFieldType == EIslandRedBlueShieldType::Red)
			SetActorControlSide(IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Red));
		else if(ForceFieldType == EIslandRedBlueShieldType::Blue)
			SetActorControlSide(IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Blue));
	}

	private void UpdateMaterialColor(bool bConstructionScript = false)
	{
		//FLinearColor TargetWallColor;
		
		switch(ForceFieldType)
		{
			case EIslandRedBlueShieldType::Red:
				TargetWallColor = RedForceFieldColor;
				break;

			case EIslandRedBlueShieldType::Blue:
				TargetWallColor = BlueForceFieldColor;
				break;

			case EIslandRedBlueShieldType::Both:
				TargetWallColor = BothForceFieldColor;
				break;
		}
		WallChangeTarget++;
		WallChangeTarget %= 2;

		if(bConstructionScript)
		{
			DynMatFront.SetVectorParameterValue(n"EmissiveColor", TargetWallColor);
			WallColor = TargetWallColor;
		}

		//DynMatFront.SetVectorParameterValue(n"EmissiveColor", WallColor);
		//DynMatFront.SetVectorParameterValue(n"RingColor", WallColor);
	}

	UFUNCTION(BlueprintPure)
	bool GetActive()
	{
		return bActive;
	}

	UFUNCTION()
	void SetForceFieldActive(bool bNewActive)
	{
		bActive = bNewActive;

		if(!bActive)
		{
			ActivationAnimation.Reverse();
			UIslandRedBlueForceFieldEffectHandler::Trigger_OnForceFieldDestroyed(this);
		}

		else
		{
			EnableForceField();
			ActivationAnimation.Play();
			UIslandRedBlueForceFieldEffectHandler::Trigger_OnForceFieldActivated(this);
		}
	}

	UFUNCTION()
	void ActivationAnimationUpdate(float CurveValue)
	{
		DynMatFront.SetScalarParameterValue(n"GlobalFade", CurveValue);
	}

	UFUNCTION()
	void ActivationAnimationFinished()
	{
		if(!bActive)
		{
			DisableForceField();
		}
	}

	private void EnableForceField()
	{
		RemoveActorDisable(this);
		CollisionMesh.RemoveComponentCollisionBlocker(this);
		WallMesh_FrontPlane.RemoveComponentVisualsBlocker(this);
	}

	
	private void DisableForceField()
	{
		AddActorDisable(this);
		CollisionMesh.AddComponentCollisionBlocker(this);
		WallMesh_FrontPlane.AddComponentVisualsBlocker(this);
		MendAllHoles();
	}

	UFUNCTION()
	void MendAllHoles()
	{
		for(int i = HoleData.Num() - 1; i >= 0; i--)
		{
			if (Network::IsGameNetworked() && HoleData[i].GrenadeOwner != nullptr)
			{
				// In networked, players mend their own holes, so the view of the holes is consistent
				if (HoleData[i].GrenadeOwner.HasControl())
					CrumbMendHole(HoleData[i].HoleIndex);
			}
			else
			{
				ResetHole(i);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMendHole(int HoleIndex)
	{
		for(int i = 0; i < HoleData.Num(); i++)
		{
			if (HoleData[i].HoleIndex == HoleIndex)
			{
				ResetHole(i);
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HandleHoleShrinking(DeltaSeconds);
		HandleMoveCompCollisionIgnoring();
		UpdateHoleLocation();
		UpdateNearbyEffect();
		CheckForSoftLock();

#if TEST
		if(bDebugHoles)
		{
			for(auto Data : HoleData)
			{
				Debug::DrawDebugSphere(GetHoleWorldLocation(Data), Data.HoleRadius, 12, FLinearColor::Red);
			}
		}
#endif
		
		WallChange = Math::FInterpTo(WallChange, WallChangeTarget, DeltaSeconds, 5); // will alternate between 0 and 1 with every switch
		float IntensityValue = (0.5 - Math::Abs(WallChange - 0.5)) * 100 + 1;

		WallColor.R = Math::FInterpTo(WallColor.R, TargetWallColor.R, DeltaSeconds, 5);
		WallColor.G = Math::FInterpTo(WallColor.G, TargetWallColor.G, DeltaSeconds, 5);
		WallColor.B = Math::FInterpTo(WallColor.B, TargetWallColor.B, DeltaSeconds, 5);
		WallColor.A = 1;
		DynMatFront.SetVectorParameterValue(n"EmissiveColor", WallColor * IntensityValue);
	}

	// Visual effect that makes the force field glow when something is near it.
	private void UpdateNearbyEffect()
	{
		for (int i = 0; i < NearbyEffectActors.Num(); i++)
		{
			if(NearbyEffectActors[i] == nullptr)
				continue;
			
			// max 4 nearby objects
			if(i >= 4)
				break;

			FVector Location = NearbyEffectActors[i].GetActorLocation();
			FVector Origin; FVector Extent;
			NearbyEffectActors[i].GetActorLocalBounds(false, Origin, Extent, false);
			WallMesh_FrontPlane.SetColorParameterValueOnMaterials(FName(f"Nearby{i}"), FLinearColor(Location.X, Location.Y, Location.Z, Extent.Size() * 1.2));
		}
		FVector AttachLocationWorld = ActorTransform.TransformPosition(AttachLocationLocal);
		WallMesh_FrontPlane.SetColorParameterValueOnMaterials(n"NearbyMine", FLinearColor(AttachLocationWorld.X, AttachLocationWorld.Y, AttachLocationWorld.Z, 100));
		
		FVector BulletHitLocationWorld = ActorTransform.TransformPosition(BulletHitLocationLocal);
		WallMesh_FrontPlane.SetColorParameterValueOnMaterials(n"BulletHit", FLinearColor(BulletHitLocationWorld.X, BulletHitLocationWorld.Y, BulletHitLocationWorld.Z, BulletHitTime));
	}

	private void CheckForSoftLock()
	{
		if(!bIsSphereForceField)
			return;

		if(!bSoftLockProtection)
			return;

		if(SoftLockLinkedForceFields.Num() == 0)
			return;

		bInsidePlayerIsSoftLocked = false;
		if(HoleDataArray.HoleData.Num() > 0)
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(IslandRedBlueWeapon::PlayerCanHitShieldType(Player, ForceFieldType))
				continue;

			float SqrDist = Player.ActorLocation.DistSquared(ActorLocation);
			if(SqrDist < Math::Square(SphereRadius))
				bInsidePlayerIsSoftLocked = true;
		}

		if(!bInsidePlayerIsSoftLocked)
			return;

		for(TSoftObjectPtr<AIslandRedBlueForceField> ForceField : SoftLockLinkedForceFields)
		{
			if(!ForceField.Get().bInsidePlayerIsSoftLocked)
				continue;

			ForceField.Get().SetForceFieldType(ForceField.Get().ForceFieldType == EIslandRedBlueShieldType::Red ? EIslandRedBlueShieldType::Blue : EIslandRedBlueShieldType::Red);
			SetForceFieldType(ForceFieldType == EIslandRedBlueShieldType::Red ? EIslandRedBlueShieldType::Blue : EIslandRedBlueShieldType::Red);
		}
	}

	private void UpdateHoleLocation()
	{
		for(int i = 0; i < HoleData.Num(); i++)
		{
			HoleData[i].bIsValidHole = IslandRedBlueWeapon::PlayerCanHitShieldType(HoleData[i].GrenadeOwner, ForceFieldType);
			if (HoleData[i].bIsValidHole)
			{
				WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(
					FName(f"Bubble{HoleData[i].MaterialParameterIndex}Loc"), 
					GetHoleWorldLocation(HoleData[i]));
			}
			else
			{
				WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(
					FName(f"Bubble{HoleData[i].MaterialParameterIndex}Loc"), 
					FVector::ZeroVector);
			}
		}
	}

	private void HandleHoleShrinking(float DeltaTime)
	{
		for(int i = 0; i < HoleData.Num(); i++)
		{
			float Radius = HoleData[i].HoleRadius;
			float CurrentShrinkSpeed = GetCurrentHoleShrinkSpeed(HoleData[i]);
			if(HasHoleStartedShrinking(HoleData[i]) && !HoleData[i].bHasStartedShrinking)
			{
				HoleData[i].bHasStartedShrinking = true;
				if(GetAmountOfHolesStartedShrinking() == 1)
				{
					FIslandRedBlueForceFieldAudioEffectParams Params;
					Params.HoleLocation = GetHoleWorldLocation(HoleData[i]);
					UIslandRedBlueForceFieldEffectHandler::Trigger_Audio_OnHoleStartShrinking(this, Params);
				}
			}

			Radius -= CurrentShrinkSpeed * DeltaTime;

			if(!HoleData[i].bHasCalledAudio_OnHoleAlmostFullyClosed && (Radius / BulletHoleMaxShrinkSpeed) <= 0.5)
			{
				HoleData[i].bHasCalledAudio_OnHoleAlmostFullyClosed = true;
				FIslandRedBlueForceFieldAudioEffectParams Params;
				Params.HoleLocation = GetHoleWorldLocation(HoleData[i]);
				UIslandRedBlueForceFieldEffectHandler::Trigger_Audio_OnHoleAlmostFullyClosed(this, Params);
			}

			if(Radius <= -0.0)
			{
				ResetHole(i);
				continue;
			}

			if (Radius != HoleData[i].HoleRadius)
				ForceFieldChangeId++;

			HoleData[i].HoleRadius = Radius;
			if(HoleData[i].bIsValidHole)
				WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(f"Bubble{HoleData[i].MaterialParameterIndex}Radius"), Radius);
			else
				WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(f"Bubble{HoleData[i].MaterialParameterIndex}Radius"), 0.0);
		}
	}

	private void HandleMoveCompCollisionIgnoring()
	{
		for(auto MoveCompData : CollisionContainerComp.IgnoreCollisionMovementComponents)
		{
			UHazeMovementComponent MoveComp = MoveCompData.MoveComp;
			UShapeComponent ShapeComp = MoveComp.GetShapeComponent();
			FCollisionShape Shape = ShapeComp.GetCollisionShape();
			FTransform ShapeTransform = ShapeComp.WorldTransform;

			if(ActorLocation.DistSquared(ShapeComp.WorldLocation) > Math::Square(2000.0))
				continue;

			bool bDebug = false;
			if(bDebugPointsOnPlayerCollision && MoveComp.Owner.IsA(AHazePlayerCharacter))
				bDebug = true;

			bool bShouldIgnoreCollision = HoleDataArray.IsShapeInsideHoles(Shape, ShapeTransform, MoveCompData.AdditionalCollisionShapeTolerance, bDebug);
			if(!bShouldIgnoreCollision && MoveCompData.bStayIgnoredWhenIgnoredOnce)
				continue;

			if(CollisionIgnoringMoveComps.Contains(MoveComp) != bShouldIgnoreCollision)
			{
				if(bShouldIgnoreCollision)
				{
					MoveComp.AddMovementIgnoresActor(this, this);
				}
				else
				{
					MoveComp.RemoveMovementIgnoresActor(this);
				}

				if(bShouldIgnoreCollision)
					CollisionIgnoringMoveComps.AddUnique(MoveComp);
				else
					CollisionIgnoringMoveComps.RemoveSingleSwap(MoveComp);
			}
		}
	}

	private void ClearAllCollisionIgnoringMoveComps()
	{
		for(UHazeMovementComponent MoveComp : CollisionIgnoringMoveComps)
		{
			MoveComp.RemoveMovementIgnoresActor(this);
		}

		CollisionIgnoringMoveComps.Reset();
	}

	private int GetAmountOfHolesStartedShrinking()
	{
		int Amount = 0;
		for(const FIslandForceFieldHoleData& Data : HoleData)
		{
			if(Data.bHasStartedShrinking)
				++Amount;
		}

		return Amount;
	}

	private bool HasHoleStartedShrinking(const FIslandForceFieldHoleData& Data)
	{
		float TimeSinceShot = Time::GetGameTimeSeconds() - Data.TimeOfShot;
		TimeSinceShot -= GetBulletHoleDelayBeforeShrinking();
		if(TimeSinceShot < 0.0)
			return false;

		if(Time::FrameNumber - Data.HoleCreatedFrame <= 1)
			return false;

		return true;
	}

	// Converts sphere hole radius to circle radius that it would have on the force field
	private float GetSignedHoleRadiusOnForceField(FVector HoleWorldLocation, float HoleRadius)
	{
		if(bIsSphereForceField)
		{
			// The problem and the solution, visualized: https://www.desmos.com/calculator/lmp5d4sg7i (red circle is grenade, blue is force field, green is circle radius on force field)
			// Formula for sphere-sphere intersection gotten from https://gamedev.stackexchange.com/questions/75756/sphere-sphere-intersection-and-circle-sphere-intersection

			// Based on formula: h = 1/2 + (r_1 * r_1 - r_2 * r_2)/(2 * d*d)
			float DistanceBetweenSpheres = HoleWorldLocation.Distance(ActorLocation);
			float D = DistanceBetweenSpheres;
			float R1 = HoleRadius;
			float R2 = SphereRadius;
			float H = 0.5 + (Math::Square(R1) - Math::Square(R2)) / (2.0 * Math::Square(D));
			// Based on formula: r_i = sqrt(r_1*r_1 - h*h*d*d)
			float NewRadius = Math::Sqrt(Math::Square(R1) - Math::Square(H) * Math::Square(D));

			return NewRadius;
		}

		return GetSignedHoleRadiusOnPlane(HoleWorldLocation, HoleRadius, ActorLocation, ActorForwardVector);
	}

	private float GetSignedHoleRadiusOnPlane(FVector HoleWorldLocation, float HoleRadius, FVector PlaneOrigin, FVector PlaneNormal, bool bCalledFromInsideItself = false)
	{
		// Radius of a circle that is a cross section of a sphere.
		// Based on formula r = sqrt(2Rh - h^2), originally found here: https://www.quora.com/How-would-I-find-the-radius-of-a-cross-section-of-a-sphere
		// R = radius of the sphere
		// a = distance from center of sphere to center of circle
		// h = R - a
		// r = radius of circle

		FVector ProjectedHoleLocation = HoleWorldLocation.PointPlaneProject(PlaneOrigin, PlaneNormal);

		float R = HoleRadius;
		float a = HoleWorldLocation.Distance(ProjectedHoleLocation);
		float h = R - a;

		// If radius of sphere is less than distance to circle center the circle would be outside the sphere so add to the radius the difference to make a signed distance.
		if(!bCalledFromInsideItself && R < a)
		{
			return GetSignedHoleRadiusOnPlane(HoleWorldLocation, a + (a - R), PlaneOrigin, PlaneNormal, true) * -1.0;
		}

		return Math::Sqrt(2 * R * h - Math::Square(h));
	}

	private FVector GetProjectedHoleLocationOnForceField(FVector HoleLocation)
	{
		if(bIsSphereForceField)
		{
			FVector CenterToEdge = (HoleLocation - ActorLocation).GetSafeNormal();
			if(CenterToEdge.IsNearlyZero())
				CenterToEdge = FVector::ForwardVector;

			return ActorLocation + CenterToEdge * SphereRadius;
		}

		return HoleLocation.PointPlaneProject(ActorLocation, ActorForwardVector);
	}

	void UpdateForceFieldMaterial()
	{
		// Reset all holes
		for(int i = 0; i < 10; i++)
		{
			WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(
				FName(f"Bubble{i}Radius"), 0.0);
			WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(
				FName(f"Bubble{i}Loc"), 
				FVector::ZeroVector);
		}

		for(int i = 0; i < HoleData.Num(); i++)
		{
			if (HoleData[i].bIsValidHole)
			{
				WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(
					FName(f"Bubble{HoleData[i].MaterialParameterIndex}Radius"), HoleData[i].HoleRadius);
				WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(
					FName(f"Bubble{HoleData[i].MaterialParameterIndex}Loc"), 
					GetHoleWorldLocation(HoleData[i]));
			}
		}
	}

	float GetCurrentHoleShrinkSpeed(const FIslandForceFieldHoleData& Data)
	{
		float TimeSinceShot = Time::GetGameTimeSeconds() - Data.TimeOfShot;
		TimeSinceShot -= GetBulletHoleDelayBeforeShrinking();
		if(TimeSinceShot < 0.0)
			return 0.0;

		return BulletHoleShrinkSpeedCurve.GetFloatValue(TimeSinceShot) * BulletHoleMaxShrinkSpeed;
	}

	float GetBulletHoleDelayBeforeShrinking() const
	{
		return BulletHoleDelayBeforeShrinking + Network::PingRoundtripSeconds;
	}

	FVector GetHoleWorldLocation(const FIslandForceFieldHoleData& Data)
	{
		return ActorTransform.TransformPosition(Data.HoleRelativeLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		BulletHitLocationLocal = ActorTransform.InverseTransformPosition(Data.ImpactLocation);
		BulletHitTime = Time::GameTimeSeconds;

		if(bBulletsShouldReflectOnSurface)
		{
			FIslandRedBlueForceFieldOnBulletReflectOnForceFieldParams Params;
			Params.WorldImpactLocation = Data.ImpactLocation;
			UIslandRedBlueForceFieldEffectHandler::Trigger_OnBulletReflectOnForceField(this, Params);
			return;
		}
	}

	FVector AttachLocationLocal;
	FVector BulletHitLocationLocal;
	float BulletHitTime;

	UFUNCTION(NotBlueprintCallable)
	private void OnAttached(FIslandRedBlueStickGrenadeOnAttachedData Data)
	{
		AttachLocationLocal = ActorTransform.InverseTransformPosition(Data.AttachedWorldLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		MakeNewHole(Data.GrenadeOwner, Data.ExplosionOrigin, Data.TotalExplosionRadius, Data.ExplosionIndex);
		AttachLocationLocal = FVector::OneVector*99999999999;
	}

	UFUNCTION()
	void MakeNewHole(AHazePlayerCharacter GrenadeOwner, FVector HoleLocation, float HoleRadius, int HoleIndex = -1)
	{
		// Usually the response components or whatever is calling MakeNewHole will already check this but there are some cases (such as exploding a grenade inside a sphere force field) that wont intersect the force field even though it's technically inside the force field itself.
		if(!HoleIntersectsForceField(HoleLocation, HoleRadius))
			return;

		FIslandForceFieldHoleData NewData;
		int Index = GetArrayIndexOfHoleWithHoleIndex(HoleIndex);
		FIslandForceFieldHoleData& Data = Index >= 0 ? HoleData[Index] : NewData;

		FVector ProjectedHoleLocation = GetProjectedHoleLocationOnForceField(HoleLocation);
		float ProjectedHoleRadius = GetSignedHoleRadiusOnForceField(HoleLocation, HoleRadius);

		// If found the same hole index and new hole has smaller radius than current, just return!
		if(Index >= 0 && ProjectedHoleRadius < Data.HoleRadius)
			return;

		Data.HoleRelativeLocation = ActorTransform.InverseTransformPosition(ProjectedHoleLocation);
		Data.HoleRadius = ProjectedHoleRadius;
		Data.MaxHoleRadius = ProjectedHoleRadius;
		Data.GrenadeOwner = GrenadeOwner;

		// If found a hole, just update it instead of creating a new one!
		if(Index >= 0)
		{
			Data.TimeOfShot = Time::GetGameTimeSeconds();
			Data.HoleCreatedFrame = GFrameNumber;
			Data.bHasStartedShrinking = false;
			ForceFieldChangeId++;
			return;
		}

		// This new circle is inside one of the already existing holes, so just don't create this new circle
		if(IsCircleInsideHoles(HoleLocation, HoleRadius))
			return;

		// Remove any bullet holes that are fully inside this new bullet hole
		for(int i = 0; i < HoleData.Num(); i++)
		{
			FIslandForceFieldHoleData Current = HoleData[i];
			if(IsCircleInsideHole(Data, GetHoleWorldLocation(Current), Current.HoleRadius))
				ResetHole(i, true);
		}

		// If there aren't any free material parameter slots, free up the oldest hole.
		if(FreeMaterialParameterIndices.Num() == 0)
		{
			ResetHole(0, true);
		}

		int MaterialIndex = FreeMaterialParameterIndices[0];
		FreeMaterialParameterIndices.RemoveAt(0);

		if(IslandRedBlueWeapon::PlayerCanHitShieldType(Data.GrenadeOwner, ForceFieldType))
		{
			WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(f"Bubble{MaterialIndex}Radius"), HoleRadius);
			WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(FName(f"Bubble{MaterialIndex}Loc"), ProjectedHoleLocation);
		}
		else
		{
			WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(f"Bubble{MaterialIndex}Radius"), 0.0);
			WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(FName(f"Bubble{MaterialIndex}Loc"), FVector::ZeroVector);
		}

		Data.MaterialParameterIndex = MaterialIndex;
		Data.TimeOfShot = Time::GetGameTimeSeconds();
		Data.HoleCreatedFrame = GFrameNumber;
		Data.HoleIndex = HoleIndex;
		HoleData.Add(Data);

		FIslandRedBlueForceFieldOnGrenadeDetonateOnForceFieldParams Params;
		Params.GrenadeExplodeLocation = HoleLocation;
		Params.GrenadeExplodeRadius = HoleRadius;
		UIslandRedBlueForceFieldEffectHandler::Trigger_OnNewHoleInForceField(this, Params);

		ForceFieldChangeId++;
	}

	private bool HoleIntersectsForceField(FVector HoleLocation, float HoleRadius)
	{
		FVector ProjectedHoleLocation = GetProjectedHoleLocationOnForceField(HoleLocation);
		if(HoleLocation.Distance(ProjectedHoleLocation) >= HoleRadius - KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	private int GetArrayIndexOfHoleWithHoleIndex(int HoleIndex)
	{
		if(HoleIndex < 0)
			return -1;

		for(int i = 0; i < HoleData.Num(); i++)
		{
			if(HoleIndex == HoleData[i].HoleIndex)
			{
				return i;
			}
		}

		return -1;
	}

	float GetSphereRadius() const property
	{
		devCheck(bIsSphereForceField, "Can't get sphere radius since this force field is not a sphere force field!");
		FBox Bounds = CollisionMesh.GetBoundingBoxRelativeToOwner();
		return Bounds.Extent.X * CollisionMesh.WorldScale.X;
	}

	bool IsPointInsideSphere(FVector Point) const
	{
		devCheck(bIsSphereForceField, "Can't check if point is inside sphere since this force field is not a sphere force field!");
		float SqrDist = Point.DistSquared(ActorLocation);;
		return SqrDist < Math::Square(SphereRadius);
	}

	void ResetHole(int HoleDataIndex, bool bCalledFromMakeNewHole = false)
	{
		devCheck(HoleDataIndex < HoleData.Num(), f"Couldn't reset hole with data index: {HoleDataIndex}, the array is {HoleData.Num()} elements");

		FIslandForceFieldHoleData Data = HoleData[HoleDataIndex];
		HoleData.RemoveAt(HoleDataIndex);

		WallMesh_FrontPlane.SetScalarParameterValueOnMaterials(FName(f"Bubble{Data.MaterialParameterIndex}Radius"), 0.0);
		WallMesh_FrontPlane.SetVectorParameterValueOnMaterials(FName(f"Bubble{Data.MaterialParameterIndex}Loc"), FVector::ZeroVector);
		FreeMaterialParameterIndices.Add(Data.MaterialParameterIndex);

		ForceFieldChangeId++;

		if(!bCalledFromMakeNewHole && HoleData.Num() == 0)
		{
			FIslandRedBlueForceFieldAudioEffectParams Params;
			Params.HoleLocation = GetHoleWorldLocation(Data);
			UIslandRedBlueForceFieldEffectHandler::Trigger_Audio_OnClosedHole(this, Params);
		}
	}

	void UpdateSphereMesh()
	{
		if(bIsSphereForceField)
		{
#if EDITOR
			if(SphereType == EIslandRedBlueForceFieldSphereType::Sphere)
			{
				auto SphereMesh = Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/LevelSpecific/Island/Abilities/ShieldShapes_01/ShieldShapes_01_Sphere.ShieldShapes_01_Sphere"));
				WallMesh_FrontPlane.StaticMesh = SphereMesh;
				CollisionMesh.StaticMesh = SphereMesh;
				CollisionMesh.RelativeScale3D = FVector(1.0);
			}
			else if(SphereType == EIslandRedBlueForceFieldSphereType::Dome)
			{
				auto DomeMesh = Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/LevelSpecific/Island/Abilities/ShieldShapes_01/ShieldShapes_01_Dome.ShieldShapes_01_Dome"));
				WallMesh_FrontPlane.StaticMesh = DomeMesh;
				CollisionMesh.StaticMesh = DomeMesh;
				// CollisionMesh.RelativeScale3D = FVector(1.0);
			}
			else
				devError("Case not handled!");
#endif
		}
	}

	/* Predicts how big the holes will be (and removes any holes that would be radius 0 or below) the specified amount of seconds in the future. This is a conservative estimate using the max shrink speed, the actual size in the future might be slightly bigger (if the holes are not yet shrinking at their max speed). */
	FIslandForceFieldHoleDataArray GetHoleDataArrayInTheFuture(float TimeInTheFuture)
	{
		devCheck(TimeInTheFuture >= 0.0, "Tried to get hole data in the future with a negative value, this is not supported!");
		if(TimeInTheFuture == 0.0)
			return HoleDataArray;

		FIslandForceFieldHoleDataArray Data = HoleDataArray;
		for(int i = Data.HoleData.Num() - 1; i >= 0; i--)
		{
			Data.HoleData[i].HoleRadius -= BulletHoleMaxShrinkSpeed * TimeInTheFuture;
			if(Data.HoleData[i].HoleRadius <= 0.0)
				Data.HoleData.RemoveAt(i);
		}

		return Data;
	}

	TArray<FIslandForceFieldHoleData>& GetHoleData() property
	{
		return HoleDataArray.HoleData;
	}

	bool IsCircleInsideHoles(FVector CircleWorldLocation, float CircleRadius)
	{
		return HoleDataArray.IsCircleInsideHoles(CircleWorldLocation, CircleRadius);
	}

	bool IsCircleInsideHole(const FIslandForceFieldHoleData& Data, FVector CircleWorldLocation, float CircleRadius)
	{
		return HoleDataArray.IsCircleInsideHole(Data, CircleWorldLocation, CircleRadius);
	}

	bool IsPointInsideHole(const FIslandForceFieldHoleData& Data, FVector PointWorldLocation)
	{
		return HoleDataArray.IsPointInsideHole(Data, PointWorldLocation);
	}

	// Will return true if the given point is inside one or several holes.
	bool IsPointInsideHoles(FVector PointWorldLocation, bool bAlsoCheckBounds = false)
	{
		return HoleDataArray.IsPointInsideHoles(PointWorldLocation);
	}

	bool IsMovementComponentIgnored(UHazeMovementComponent MoveComp)
	{
		return CollisionIgnoringMoveComps.Contains(MoveComp);
	}
}

#if TEST
struct FIslandForceFieldHoleTemporalLogData
{
	FVector HoleRelativeLocation;
	float HoleRadius;
}

struct FIslandForceFieldHolesTemporalLogData
{
	TArray<FIslandForceFieldHoleTemporalLogData> Holes;
	int Frame;
}

UCLASS(HideCategories = "Rendering Cooking Activation ComponentTick Physics Lod Collision")
class UIslandRedBlueForceFieldHoleLoggerComponent : UHazeTemporalLogScrubbableComponent
{
	private TArray<FIslandForceFieldHolesTemporalLogData> TemporalFrames;
	private AIslandRedBlueForceField ForceField;
	private const int MaxFrameCount = 100000;
	private int LoggedFrameCount = 0;

	TOptional<FIslandForceFieldHoleDataArray> OriginalHoleData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceField = Cast<AIslandRedBlueForceField>(Owner);
		LoggedFrameCount = 0;
		TemporalFrames.Empty(MaxFrameCount);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogRecordedFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		FIslandForceFieldHolesTemporalLogData TemporalFrameState;
		TemporalFrameState.Frame = LogFrameNumber;
		GetHoleDataArray(TemporalFrameState.Holes);
		
		int Index = LoggedFrameCount % MaxFrameCount;
		if (Index < TemporalFrames.Num())
			TemporalFrames[Index] = TemporalFrameState;	
		else
			TemporalFrames.Add(TemporalFrameState);

		LoggedFrameCount += 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogScrubbedToFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		if(!OriginalHoleData.IsSet())
			OriginalHoleData.Set(ForceField.HoleDataArray);

		FIslandForceFieldHolesTemporalLogData Data = BinaryFindIndex(LogFrameNumber);
		SetHoleDataArray(Data.Holes);
		ForceField.UpdateForceFieldMaterial();
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		if(!OriginalHoleData.IsSet())
			return;

		ForceField.HoleDataArray = OriginalHoleData.Value;
		ForceField.UpdateForceFieldMaterial();
		OriginalHoleData.Reset();
	}

	protected FIslandForceFieldHolesTemporalLogData BinaryFindIndex(int FrameNumberToFind) const
	{
		int IndexOffset = LoggedFrameCount % MaxFrameCount;

		int StartAbsIndex = Math::Max(0, LoggedFrameCount - MaxFrameCount);
		int EndAbsIndex = LoggedFrameCount - 1;

		while (EndAbsIndex >= StartAbsIndex) 
		{
			const int MiddleAbsIndex = StartAbsIndex + Math::IntegerDivisionTrunc((EndAbsIndex - StartAbsIndex), 2); 
			const int MiddleRealIndex = Math::WrapIndex(IndexOffset - (LoggedFrameCount - MiddleAbsIndex), 0, MaxFrameCount);

			const FIslandForceFieldHolesTemporalLogData& FrameData = TemporalFrames[MiddleRealIndex];
	
			if (FrameData.Frame == FrameNumberToFind)
			 	return TemporalFrames[MiddleRealIndex];
			
			if(FrameData.Frame < FrameNumberToFind)
				StartAbsIndex = MiddleAbsIndex + 1;
			else
				EndAbsIndex = MiddleAbsIndex - 1;
		}
		return FIslandForceFieldHolesTemporalLogData();
	}

	void GetHoleDataArray(TArray<FIslandForceFieldHoleTemporalLogData>& HoleData)
	{
		for(FIslandForceFieldHoleData Data : ForceField.HoleDataArray.HoleData)
		{
			if(!Data.bIsValidHole)
				return;

			FIslandForceFieldHoleTemporalLogData NewData;
			NewData.HoleRadius = Data.HoleRadius;
			NewData.HoleRelativeLocation = Data.HoleRelativeLocation;
			HoleData.Add(NewData);
		}
	}

	void SetHoleDataArray(const TArray<FIslandForceFieldHoleTemporalLogData>& HoleData)
	{
		ForceField.HoleDataArray.HoleData.Reset();
		int MaterialIndex = 0;
		for(FIslandForceFieldHoleTemporalLogData Data : HoleData)
		{
			FIslandForceFieldHoleData NewData;
			NewData.HoleRadius = Data.HoleRadius;
			NewData.HoleRelativeLocation = Data.HoleRelativeLocation;
			NewData.MaterialParameterIndex = MaterialIndex;
			NewData.bIsValidHole = true;
			ForceField.HoleDataArray.HoleData.Add(NewData);
			MaterialIndex++;
		}
	}
}
#endif
