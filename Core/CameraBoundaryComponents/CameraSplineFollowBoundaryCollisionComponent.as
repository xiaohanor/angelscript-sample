// This exists so we can use the same code for the editor visualization and for runtime
struct FCameraSplineFollowBoundaryCollisionContextData
{
	FVector WorldUp;
	UHazeSplineComponent Spline;
	ASplineFollowCameraActor CameraActor;
	private const UHazeCameraUserComponent Internal_UserComp;
	private AHazePlayerCharacter Internal_Player;

	FTransform GetCameraTransform() const property
	{
		if(Internal_UserComp == nullptr)
			return CameraActor.Camera.WorldTransform;

		return Internal_UserComp.ViewTransform;
	}

	void SetPlayer(AHazePlayerCharacter Player) property
	{
		Internal_Player = Player;
	}

	void SetUserComp(const UHazeCameraUserComponent UserComp) property
	{
		Internal_UserComp = UserComp;
	}

	FVector GetFocusTargetLocation() const
	{
#if EDITOR
		if(Internal_Player == nullptr)
		{
			FFocusTargets FocusTargets = CameraActor.FocusTargetComponent.GetEditorPreviewTargets();
			return FocusTargets.GetWeightedCenter();
		}
#endif

		FFocusTargets FocusTargets = CameraActor.FocusTargetComponent.GetFocusTargets(Internal_Player);
		return FocusTargets.GetWeightedCenter();
	}
}

enum ECameraSplineFollowBoundaryCollisionLocationRelativeType
{
	/* Location of the focus target the camera is looking at. */
	FocusTarget,
	/* Closest location on the spline to the focus target */
	SplineCloseToFocusTarget,
	/* Location of the camera this component is attached to. */
	Camera,
	/* Closest location on the spline to the camera */
	SplineCloseToCamera,
}

// This rotation determines the transform that the relative location is relative to.
enum ECameraSplineFollowBoundaryCollisionRotationRelativeType
{
	/* Rotation of spline transform closest to the location the collider is relative to. */
	SplineCloseToLocationRelativeTo,
	/* Rotation of spline transform at colliders spline location */
	SplineCloseToCollider,
	/* Rotation of the camera this component is attached to. */
	Camera,
	/* Rotation of the camera but constrained to the world up of the player using this camera. */
	HorizontalCamera
}

struct FCameraSplineFollowBoundaryColliderLocationData
{
	// What location the relative location and spline distance offset should be relative to.
	UPROPERTY()
	ECameraSplineFollowBoundaryCollisionLocationRelativeType LocationRelativeType;

	// What rotation the relative location should be relative to.
	UPROPERTY()
	ECameraSplineFollowBoundaryCollisionRotationRelativeType RotationRelativeType;

	/* Will get the closest spline distance to the location relative type and add this offset to determine the location of the collider. */
	UPROPERTY()
	float ColliderSplineDistanceOffset = 0.0;

	// The collider relative location (relative to the selected Relative Types above)
	UPROPERTY()
	FVector ColliderRelativeLocation;
}

enum ECameraSplineFollowBoundaryCollisionRotationType
{
	/* Rotation is world rotation. */
	World,
	/* Rotation is relative to spline rotation closest to colliders spline distance offset. */
	SplineCloseToCollider,
	/* Rotation is relative to spline rotation closest to the location of the transform the relative location is relative to. */
	SplineCloseToLocationRelativeTo,
	/* Rotation is relative to camera this component is attached to. */
	Camera,
	/* Rotation is relative to camera rotation constrained to the world up of the player using this camera. */
	HorizontalCamera,
}

struct FCameraSplineFollowBoundaryColliderRotationData
{
	/* This is what the collider rotation is relative to */
	UPROPERTY()
	ECameraSplineFollowBoundaryCollisionRotationType RotationType;

	/* The collider rotation (relative to Rotation Type) */
	UPROPERTY()
	FRotator ColliderRotation;
}

struct FCameraSplineFollowBoundaryColliderData
{
	access Component = private, UCameraSplineFollowBoundaryCollisionComponent;

	UPROPERTY()
	FCameraSplineFollowBoundaryColliderLocationData LocationData;

	UPROPERTY()
	FCameraSplineFollowBoundaryColliderRotationData RotationData;

	UPROPERTY()
	FVector BoxExtents = FVector(50.0);

	UPROPERTY()
	FName CollisionProfileName = n"BlockOnlyPlayerCharacter";

	access:Component ACameraSplineFollowBoundaryCollisionActor CollisionActor;
}

UCLASS(NotBlueprintable, NotPlaceable)
class ACameraSplineFollowBoundaryCollisionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default Collision.bGenerateOverlapEvents = false;
	default Collision.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	default Collision.RemoveTag(ComponentTags::Walkable);
	default Collision.RemoveTag(ComponentTags::LedgeClimbable);
	default Collision.RemoveTag(ComponentTags::LedgeRunnable);
	default Collision.RemoveTag(ComponentTags::DarkPortalPlaceable);
}

class UCameraSplineFollowBoundaryCollisionComponent : UHazeCameraResponseComponent
{
	access Visualizer = private, UCameraSplineFollowBoundaryCollisionComponentVisualizer;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere)
	TArray<FCameraSplineFollowBoundaryColliderData> Colliders;

	// If a disabled instigator should be added on BeginPlay, the colliders wont be active regardless until the camera is active!
	UPROPERTY(EditAnywhere)
	bool bStartDisabled = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bStartDisabled", EditConditionHides))
	FName StartDisabledInstigator = n"StartDisabled";

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Debug")
	bool bDebugDrawColliders = false;

	UPROPERTY(EditAnywhere, Category = "Debug", Meta = (EditCondition = "bDebugDrawColliders", EditConditionHides))
	float DebugDrawLineThickness = 5.0;

	UPROPERTY(EditAnywhere, Category = "Debug", Meta = (EditCondition = "bDebugDrawColliders", EditConditionHides))
	FLinearColor DebugDrawColor = FLinearColor::Red;

	UPROPERTY(EditAnywhere, Category = "Editor")
	bool bEditorOnlyVisualizeWhenSelected = true;

	UPROPERTY(EditAnywhere, Category = "Editor")
	bool bEditorDrawSolidBoxes = false;

	UPROPERTY(EditAnywhere, Category = "Editor")
	float EditorLineThickness = 5.0;

	UPROPERTY(EditAnywhere, Category = "Editor", Meta = (EditCondition = "bDrawSolidBox", EditConditionHides))
	float EditorSolidBoxOpacity = 0.3;

	UPROPERTY(EditAnywhere, Category = "Editor")
	FLinearColor EditorColor = FLinearColor::Red;

	/* Used when constraining camera rotation to horizontal only */
	UPROPERTY(EditAnywhere, Category = "Editor")
	FVector EditorPreviewWorldUp = FVector::UpVector;
#endif

	private TArray<FInstigator> DisableInstigators;
	private TArray<UHazeCameraUserComponent> ActiveUserComps;
	private bool bCollidersAreEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto CameraActor = Cast<ASplineFollowCameraActor>(Owner);
		devCheck(CameraActor != nullptr, "UCameraSplineFollowBoundaryCollisionComponent placed on an actor that isn't a ASplineFollowCameraActor, this is not supported!");

		if(bStartDisabled)
			DisableCollision(StartDisabledInstigator);

		SpawnColliders();
		UpdateCollidersEnabled();

#if EDITOR
		if(bDebugDrawColliders)
			SetComponentTickEnabled(true);
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bCollidersAreEnabled)
			return;

		DebugDrawColliders();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnCameraUpdateForUser(const UHazeCameraUserComponent HazeUser, float DeltaTime)
	{
		UpdateCollidersEnabled();
		if(!bCollidersAreEnabled)
			return;

		HandleMoveColliders(HazeUser, HazeUser.GetPlayerOwner());
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraSnapForUser(const UHazeCameraUserComponent HazeUser)
	{
		UpdateCollidersEnabled();
		if(!bCollidersAreEnabled)
			return;

		HandleMoveColliders(HazeUser, HazeUser.GetPlayerOwner());
	}

	private void HandleMoveColliders(const UHazeCameraUserComponent HazeUser, AHazePlayerCharacter Player)
	{
		FCameraSplineFollowBoundaryCollisionContextData Context;
		GetContextData(Player, HazeUser, Context);

		for(const FCameraSplineFollowBoundaryColliderData& Data : Colliders)
		{
			FTransform ColliderTransform = GetTransformForCollider(Data, Context);
			Data.CollisionActor.ActorTransform = ColliderTransform;
		}
	}

	FTransform GetTransformForCollider(const FCameraSplineFollowBoundaryColliderData& ColliderData, FCameraSplineFollowBoundaryCollisionContextData Context)
	{
		FTransform LocationRelativeTransform = GetLocationRelativeTransform(Context, ColliderData);
		FVector Location = GetColliderLocation(ColliderData, LocationRelativeTransform, Context);

		FRotator RelativeRotation = GetRotationRelativeRotation(Context, LocationRelativeTransform, Location, ColliderData);
		FRotator Rotation = GetColliderRotation(ColliderData, RelativeRotation);

		return FTransform(Rotation, Location);
	}
		
	private FVector GetColliderLocation(const FCameraSplineFollowBoundaryColliderData& Data, FTransform RelativeTo, FCameraSplineFollowBoundaryCollisionContextData Context)
	{
		FVector Location = RelativeTo.Location;

		if(Data.LocationData.ColliderSplineDistanceOffset != 0.0)
		{
			float SplineDistance = Context.Spline.GetClosestSplineDistanceToWorldLocation(RelativeTo.Location);
			SplineDistance += Data.LocationData.ColliderSplineDistanceOffset;
			Location = Context.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		}

		if(!Data.LocationData.ColliderRelativeLocation.IsZero())
		{
			FVector Offset = RelativeTo.TransformVector(Data.LocationData.ColliderRelativeLocation);
			Location += Offset;
		}

		return Location;
	}

	private FRotator GetColliderRotation(const FCameraSplineFollowBoundaryColliderData& Data, FRotator RelativeRotation)
	{
		FTransform RotTransform = FTransform(RelativeRotation);
		FRotator Rotation = RotTransform.TransformRotation(Data.RotationData.ColliderRotation);
		return Rotation;
	}

	private FTransform GetLocationRelativeTransform(FCameraSplineFollowBoundaryCollisionContextData Context, FCameraSplineFollowBoundaryColliderData Data) const
	{
		FVector Location = FVector::ZeroVector;
		switch(Data.LocationData.LocationRelativeType)
		{
			case ECameraSplineFollowBoundaryCollisionLocationRelativeType::FocusTarget:
			{
				Location = Context.GetFocusTargetLocation();
				break;
			}
			case ECameraSplineFollowBoundaryCollisionLocationRelativeType::SplineCloseToFocusTarget:
			{
				Location = Context.GetFocusTargetLocation();
				Location = Context.Spline.GetClosestSplineWorldLocationToWorldLocation(Location);
				break;
			}
			case ECameraSplineFollowBoundaryCollisionLocationRelativeType::Camera:
			{
				Location = Context.CameraTransform.Location;
				break;
			}
			case ECameraSplineFollowBoundaryCollisionLocationRelativeType::SplineCloseToCamera:
			{
				Location = Context.CameraTransform.Location;
				Location = Context.Spline.GetClosestSplineWorldLocationToWorldLocation(Location);
				break;
			}
			default:
				devError("Forgot to add case!");
		}

		FRotator Rotation = FRotator::ZeroRotator;
		switch(Data.LocationData.RotationRelativeType)
		{
			case ECameraSplineFollowBoundaryCollisionRotationRelativeType::SplineCloseToLocationRelativeTo:
			{
				Rotation = Context.Spline.GetClosestSplineWorldRotationToWorldLocation(Location).Rotator();
				break;
			}
			case ECameraSplineFollowBoundaryCollisionRotationRelativeType::SplineCloseToCollider:
			{
				float SplineDistance = Context.Spline.GetClosestSplineDistanceToWorldLocation(Location);
				SplineDistance += Data.LocationData.ColliderSplineDistanceOffset;
				Rotation = Context.Spline.GetWorldRotationAtSplineDistance(SplineDistance).Rotator();
				break;
			}
			case ECameraSplineFollowBoundaryCollisionRotationRelativeType::Camera:
			{
				Rotation = Context.CameraTransform.Rotator();
				break;
			}
			case ECameraSplineFollowBoundaryCollisionRotationRelativeType::HorizontalCamera:
			{
				FVector Forward = Context.CameraTransform.Rotation.ForwardVector.VectorPlaneProject(Context.WorldUp);
				Rotation = FRotator::MakeFromXZ(Forward, Context.WorldUp);
				break;
			}
			default:
				devError("Forgot to add case!");
		}

		return FTransform(Rotation, Location);
	}

	private FRotator GetRotationRelativeRotation(FCameraSplineFollowBoundaryCollisionContextData Context, FTransform LocationRelativeTransform, FVector ColliderLocation,
		FCameraSplineFollowBoundaryColliderData Data)
	{
		switch(Data.RotationData.RotationType)
		{
			case ECameraSplineFollowBoundaryCollisionRotationType::World:
			{
				return FRotator::ZeroRotator;
			}
			case ECameraSplineFollowBoundaryCollisionRotationType::SplineCloseToCollider:
			{
				return Context.Spline.GetClosestSplineWorldRotationToWorldLocation(ColliderLocation).Rotator();
			}
			case ECameraSplineFollowBoundaryCollisionRotationType::SplineCloseToLocationRelativeTo:
			{
				return Context.Spline.GetClosestSplineWorldRotationToWorldLocation(LocationRelativeTransform.Location).Rotator();
			}
			case ECameraSplineFollowBoundaryCollisionRotationType::Camera:
			{
				return Context.CameraTransform.Rotator();
			}
			case ECameraSplineFollowBoundaryCollisionRotationType::HorizontalCamera:
			{
				FVector Forward = Context.CameraTransform.Rotation.ForwardVector.VectorPlaneProject(Context.WorldUp);
				return FRotator::MakeFromXZ(Forward, Context.WorldUp);
			}
			default:
				devError("Forgot to add case!");
		}

		return FRotator();
	}

	private void GetContextData(AHazePlayerCharacter Player, const UHazeCameraUserComponent UserComp, FCameraSplineFollowBoundaryCollisionContextData& Context)
	{
		Context.CameraActor = Cast<ASplineFollowCameraActor>(Owner);
		Context.UserComp = UserComp;
		Context.Player = Player;
		Context.Spline = Context.CameraActor.GetSplineToUse();
		Context.WorldUp = Player.MovementWorldUp;
	}

#if EDITOR
	access:Visualizer
	void GetEditorContextData(FCameraSplineFollowBoundaryCollisionContextData& Context)
	{
		Context.CameraActor = Cast<ASplineFollowCameraActor>(Owner);
		Context.Spline = Context.CameraActor.GetSplineToUse();
		Context.WorldUp = EditorPreviewWorldUp;
	}
#endif

	private void SpawnColliders()
	{
		for(int i = 0; i < Colliders.Num(); i++)
		{
			auto Collision = SpawnActor(ACameraSplineFollowBoundaryCollisionActor);
			Colliders[i].CollisionActor = Collision;
			Colliders[i].CollisionActor.Collision.BoxExtent = Colliders[i].BoxExtents;
			Colliders[i].CollisionActor.Collision.CollisionProfileName = Colliders[i].CollisionProfileName;
			Colliders[i].CollisionActor.AddActorDisable(this);
		}
	}

	private void UpdateCollidersEnabled()
	{
		bool bShouldBeEnabled = IsCollisionEnabled();
		if(bShouldBeEnabled == bCollidersAreEnabled)
			return;

		for(int i = 0; i < Colliders.Num(); i++)
		{
			if(bShouldBeEnabled)
				Colliders[i].CollisionActor.RemoveActorDisable(this);
			else
				Colliders[i].CollisionActor.AddActorDisable(this);
		}

		bCollidersAreEnabled = bShouldBeEnabled;
	}

#if EDITOR
	private void DebugDrawColliders()
	{
		for(const FCameraSplineFollowBoundaryColliderData& Data : Colliders)
		{
			Debug::DrawDebugBox(Data.CollisionActor.ActorLocation, Data.BoxExtents, Data.CollisionActor.ActorRotation, DebugDrawColor, DebugDrawLineThickness);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User)
	{
		ActiveUserComps.AddUnique(User);
		UpdateCollidersEnabled();
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent User)
	{
		ActiveUserComps.RemoveSingleSwap(User);
		UpdateCollidersEnabled();
	}

	UFUNCTION(BlueprintPure)
	bool IsCollisionEnabled() const
	{
		if(DisableInstigators.Num() > 0)
			return false;

		if(ActiveUserComps.Num() == 0)
			return false;

		if(ActiveUserComps.Num() == 2 && !IsAnyActiveUserPendingFullscreen())
			return false;

		return true;
	}

	UFUNCTION()
	void DisableCollision(FInstigator Instigator)
	{
		DisableInstigators.AddUnique(Instigator);
		UpdateCollidersEnabled();
	}

	UFUNCTION()
	void EnableCollision(FInstigator Instigator)
	{
		DisableInstigators.RemoveSingleSwap(Instigator);
		UpdateCollidersEnabled();
	}

	private bool IsAnyActiveUserPendingFullscreen() const
	{
		for(UHazeCameraUserComponent User : ActiveUserComps)
		{
			AHazePlayerCharacter Player = User.GetPlayerOwner();

			if(Player.IsPendingFullscreen())
				return true;
		}

		return false;
	}
}

#if EDITOR
class UCameraSplineFollowBoundaryCollisionComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCameraSplineFollowBoundaryCollisionComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto BoundaryComp = Cast<UCameraSplineFollowBoundaryCollisionComponent>(Component);

		if(BoundaryComp.bEditorOnlyVisualizeWhenSelected && !Editor::SelectedComponents.Contains(Component))
			return;

		FCameraSplineFollowBoundaryCollisionContextData Context;
		BoundaryComp.GetEditorContextData(Context);
		
		for(int i = 0; i < BoundaryComp.Colliders.Num(); i++)
		{
			const FCameraSplineFollowBoundaryColliderData& Data = BoundaryComp.Colliders[i];
			FTransform ColliderTransform = BoundaryComp.GetTransformForCollider(Data, Context);
			if(BoundaryComp.bEditorDrawSolidBoxes)
				DrawSolidBox(FInstigator(BoundaryComp, FName(f"Collider {i}")), ColliderTransform.Location, ColliderTransform.Rotation, Data.BoxExtents, BoundaryComp.EditorColor, BoundaryComp.EditorSolidBoxOpacity, BoundaryComp.EditorLineThickness);
			else
				DrawWireBox(ColliderTransform.Location, Data.BoxExtents, ColliderTransform.Rotation, BoundaryComp.EditorColor, BoundaryComp.EditorLineThickness);

			DrawWorldString(f"Collider: {i}", ColliderTransform.Location, BoundaryComp.EditorColor, 1.0, -1.0, false, true);
		}
	}
}
#endif