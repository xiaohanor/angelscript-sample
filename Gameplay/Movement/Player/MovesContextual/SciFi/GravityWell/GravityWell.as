/*
	TODO:
	- Override Speed
	- Override Launch velocity
*/
UCLASS(Abstract)
class AGravityWell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UAutoScaleSplineBoxComponent AutoScaleBoxComponent;
	default AutoScaleBoxComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(DefaultComponent)
	UArrowComponent ExitDirection;
	default ExitDirection.SetbAbsoluteScale(true);
	default ExitDirection.SetRelativeScale3D(FVector(5.0, 5.0, 5.0));

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestSheetComponent;

	UPROPERTY(DefaultComponent)
	UEditorGravityWellDebugComponent DebugComponent;

	// UPROPERTY(DefaultComponent)
	// UGravityWellTargetPoint TargetPoint;
	// UPROPERTY(DefaultComponent)
	// UGravityWellDrawComponent DrawComp;

	default bRunConstructionScriptOnDrag = true;


	UPROPERTY(Category = Settings, EditAnywhere)
	bool bStartEnabled = true;

	UPROPERTY(Category = Settings, EditAnywhere)
	UPlayerGravityWellSettings SettingsAsset;

	/** 
	 * If true, well counts as an elevator
	 * If false, its like a water slide.
	*/
	UPROPERTY(Category = Settings, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	bool bIsVerticalWell = true;

	// The radius of the well from the center of the spline
	UPROPERTY(Category = Settings, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides, ClampMin="0.0", UIMin="0.0"))
	protected float Radius = 400.0;

	UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected float ForwardSpeed = 400.0;

	UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected float ForwardSpeedInterpSpeed = 3.0;

	UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected float PlayerPlaneMoveSpeed = 600.0;

	UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected float PullToCenterStrength = 3.0;

	// If this is set to false, the player can float out of the well
	UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected bool bLockPlayerInsideWell = true;

	// How close to the edge of the edge of the well the player can get
	UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr && bLockPlayerInsideWell", EditConditionHides))
	protected float LockPlayerMargin = 80.0;

	// UPROPERTY(Category = Settings|Movement, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	// protected bool bRotatePlayerInWellMovement = true;

	UPROPERTY(Category = Settings|Launch, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected float LaunchSpeed = 2000.0;

	UPROPERTY(Category = Settings|Launch, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected float LaunchGravity = 2000.0;

	UPROPERTY(Category = Settings|Camera, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected UHazeCameraSpringArmSettingsDataAsset CameraSettings = nullptr;

	UPROPERTY(Category = Settings|Camera, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	protected bool bEnableFollowCamera = true;

	// THIS IS NOT USED ANYMORE
	UPROPERTY(Category = Settings|Launch, VisibleAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	EGravityWellLaunchDeactivationMode LaunchDeactivationMode = EGravityWellLaunchDeactivationMode::ImpactsOnly;

	// only used if >= 0
	UPROPERTY(Category = Settings|Launch, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	float LaunchDeactivateAfterDuration = 8.0;

	UPROPERTY(Category = Settings|Launch, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	bool LaunchDeactivateOnImpacts = true;

	UPROPERTY(Category = Settings|Launch, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	bool LaunchDeactivateOnFalling = false;

	UPROPERTY(Category = Settings|Launch, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides))
	bool LaunchDeactivateIfOutsideWell = false;




	/*
		- if 0 will look in the direction of the tangent
		- if greater than 0, will look a point ahead of the player.
			Any overshoot to the target will instead be in the launch direction
	*/
	UPROPERTY(Category = Settings|Camera, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr&&bEnableFollowCamera", EditConditionHides))
	protected float CameraLookAtDistance = 600.0;


	UPROPERTY(Category = "Default Settings", EditAnywhere, EditDefaultsOnly)
	UStaticMesh GravityWellMesh;

	UPROPERTY(Category = "Default Settings", EditAnywhere, EditDefaultsOnly)
	UMaterialInstance GravityWellMaterial;


	UPROPERTY(NotEditable)
	TArray<USplineMeshComponent> SplineMeshes;
	
	bool bEnabled = true;
	float ExitTargetDistanceAlongSpline = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AutoScaleBoxComponent.BoxMargin = FVector(DefaultRadius + 500.0, DefaultRadius + 500.0, DefaultRadius + 500.0);
		ExitDirection.WorldLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(ExitDirection.WorldLocation);

		CreateSplineMeshes();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bEnabled = bStartEnabled;
		AutoScaleBoxComponent.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		AutoScaleBoxComponent.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");

		ExitTargetDistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(ExitDirection.WorldLocation);
	}

	void ApplySettings(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (SettingsAsset != nullptr)
			Player.ApplySettings(SettingsAsset, Instigator);
		else
		{
			UPlayerGravityWellSettings::SetIsVerticalWell(Player, bIsVerticalWell, Instigator);
			UPlayerGravityWellSettings::SetRadius(Player, Radius, Instigator);
			UPlayerGravityWellSettings::SetForwardSpeed(Player, ForwardSpeed, Instigator);
			UPlayerGravityWellSettings::SetForwardSpeedInterpSpeed(Player, ForwardSpeedInterpSpeed, Instigator);
			UPlayerGravityWellSettings::SetPlayerPlaneMoveSpeed(Player, PlayerPlaneMoveSpeed, Instigator);
			UPlayerGravityWellSettings::SetPullToCenterStrength(Player, PullToCenterStrength, Instigator);
			UPlayerGravityWellSettings::SetLockPlayerInsideWell(Player, bLockPlayerInsideWell, Instigator);
			UPlayerGravityWellSettings::SetLockPlayerMargin(Player, LockPlayerMargin, Instigator);
			UPlayerGravityWellSettings::SetLaunchDeactivateAfterDuration(Player, LaunchDeactivateAfterDuration, Instigator);
			UPlayerGravityWellSettings::SetLaunchDeactivateOnImpacts(Player, LaunchDeactivateOnImpacts, Instigator);
			UPlayerGravityWellSettings::SetLaunchDeactivateOnFalling(Player, LaunchDeactivateOnFalling, Instigator);
			UPlayerGravityWellSettings::SetLaunchDeactivateIfOutsideWell(Player, LaunchDeactivateIfOutsideWell, Instigator);
			UPlayerGravityWellSettings::SetLaunchSpeed(Player, LaunchSpeed, Instigator);
			UPlayerGravityWellSettings::SetLaunchGravity(Player, LaunchGravity, Instigator);	
			UPlayerGravityWellSettings::SetEnableFollowCamera(Player, bEnableFollowCamera, Instigator);
		}
	}

	UFUNCTION()
	void EnableGravityWell()
	{
		bEnabled = true;
	}

	UFUNCTION()
	void DisableGravityWell()
	{
		bEnabled = false;
	}

	UFUNCTION()
	void StartEnterGuidanceForPlayer(AHazePlayerCharacter Player, FPlayerGravityWellGuidanceActivationParams GuidanceSettings)
	{
		if (Player == nullptr)
			return;
		if(!Player.HasControl())
			return;
		auto GravComp = UPlayerGravityWellComponent::Get(Player);
		GravComp.AddNearbyGravityWell(this);
		GravComp.GuidedEnterWell = this;
		GravComp.GuidanceSettings = GuidanceSettings;
	}

	UFUNCTION()
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent,
		int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		auto GravComp = UPlayerGravityWellComponent::Get(Player);
		GravComp.AddNearbyGravityWell(this);
	}

	UFUNCTION()
	void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		auto GravComp = UPlayerGravityWellComponent::Get(Player);
		if (GravComp == nullptr)
			return;
		GravComp.RemoveNearbyGravityWell(this);
	}

	float GetDefaultRadius() const property
	{
		return SettingsAsset == nullptr ? Radius : SettingsAsset.Radius;
	}

	float GetDefaultLockMargin() const property
	{
		return SettingsAsset == nullptr ? LockPlayerMargin : SettingsAsset.LockPlayerMargin;
	}

	bool IsVerticalWell() const
	{
		return SettingsAsset == nullptr ? bIsVerticalWell : SettingsAsset.bIsVerticalWell;
	}

	bool IsWorldLocationInsideWell(FVector WorldLocation) const
	{
		FVector NearestSplineLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(WorldLocation);
		FVector ToNearestLocation = NearestSplineLocation - WorldLocation;
		return ToNearestLocation.Size() <= DefaultRadius;
	}

	protected void CreateSplineMeshes()
	{
		SplineMeshes.Empty();

#if EDITOR
		int SplineMeshCount = Spline.SplinePoints.Num() - 1;
		if (Spline.IsClosedLoop())
			SplineMeshCount += 1;

		for (int Index = 0, Count = SplineMeshCount; Index < Count; ++ Index)
		{
			USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this);
			SplineMesh.SetStaticMesh(GravityWellMesh);
			SplineMesh.SetMaterial(0, GravityWellMaterial);
			SplineMesh.SetMaterial(1, GravityWellMaterial);
			SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			SplineMesh.SetCastShadow(false);		
			
			// Attempt at fixing twisting /shrug
			SplineMesh.SetSmoothInterpRollScale(true);
			float Distance = Spline.GetSplineDistanceAtSplinePointIndex(Index);
			FQuat Rotation = Spline.GetWorldRotationAtSplineDistance(Distance);
			SplineMesh.SetSplineUpDir(Rotation.UpVector);

			SplineMeshes.Add(SplineMesh);
		}

		UpdateSplineMeshes();
#endif
	}

	protected void UpdateSplineMeshes()
	{
		for (USplineMeshComponent SplineMesh : SplineMeshes)
		{
			int StartIndex = SplineMeshes.FindIndex(SplineMesh);
			int EndIndex = StartIndex + 1;

			if (Spline.IsClosedLoop() && EndIndex >= Spline.SplinePoints.Num())
				EndIndex = 0;

			float StartDistance = Spline.GetSplineDistanceAtSplinePointIndex(StartIndex);
			FVector StartLocation = Spline.GetRelativeLocationAtSplineDistance(StartDistance);
			FVector StartTangent = Spline.GetRelativeTangentAtSplineDistance(StartDistance);

			float EndDistance = Spline.GetSplineDistanceAtSplinePointIndex(EndIndex);
			FVector EndLocation = Spline.GetRelativeLocationAtSplineDistance(EndDistance);
			FVector EndTangent = Spline.GetRelativeTangentAtSplineDistance(EndDistance);
			SplineMesh.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);

			// Update mesh scale by scale
			float MeshScale = DefaultRadius / 50.0;
			SplineMesh.SetStartScale(FVector2D(MeshScale, MeshScale));
			SplineMesh.SetEndScale(FVector2D(MeshScale, MeshScale));
		}
	}
}

enum EGravityWellLaunchDeactivationMode
{
	ImpactsOnly,
	Duration,
	Falling,
	OutsideOfWell
}

struct FPlayerGravityWellActivationParams
{
	AGravityWell GravityWell;
}


class UEditorGravityWellDebugComponent : USceneComponent
{
	default bIsEditorOnly = true;

	UPROPERTY(EditAnywhere)
	bool bShowDebug = true;
}

#if EDITOR
class UEditorGravityWellDebugComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UEditorGravityWellDebugComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto Comp = Cast<UEditorGravityWellDebugComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		if(!Comp.bShowDebug)
			return;
		
		auto Well = Cast<AGravityWell>(Component.Owner);
		auto Spline = Well.Spline;

		FSplinePosition SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(GetEditorViewLocation() + (GetEditorViewRotation().ForwardVector * 2000.0));
		
		FQuat DebugRotation = SplinePosition.WorldRotation;
		DebugRotation *= FRotator(90.0, 0.0, 0.0).Quaternion();

		DrawWireCylinder(SplinePosition.WorldLocation, DebugRotation.Rotator() , FLinearColor::Blue, Well.DefaultRadius, 200.0, 24.0, 4.0);
		float InnerRadius = Well.DefaultRadius - Well.DefaultLockMargin;
		if(InnerRadius > 0 && !Math::IsNearlyZero(InnerRadius - Well.DefaultLockMargin))
			DrawWireCylinder(SplinePosition.WorldLocation, DebugRotation.Rotator(), FLinearColor::Red, InnerRadius, 200.0, 24.0, 4.0);

		FVector ArrowLocation = SplinePosition.WorldLocation + (GetEditorViewRotation().UpVector * 100.0);
		FVector ArrowDelta = SplinePosition.WorldForwardVector * 500.0;
		DrawArrow(ArrowLocation - ArrowDelta, ArrowLocation + ArrowDelta, FLinearColor::Blue, 100.0, 10.0);

		FRotator SplineOrientation;
		if(SplinePosition.WorldForwardVector.DotProduct(FVector::UpVector) > 1.0 - KINDA_SMALL_NUMBER)
			SplineOrientation = FRotator::MakeFromXZ(SplinePosition.WorldForwardVector, FVector::RightVector);
		else
			SplineOrientation = FRotator::MakeFromXZ(SplinePosition.WorldForwardVector, FVector::UpVector);
		DrawArrow(ArrowLocation, ArrowLocation + (SplineOrientation.UpVector * 500), FLinearColor::Green, 100.0, 10.0);

		DrawWorldString(f"Dist {SplinePosition.CurrentSplineDistance :.0}", SplinePosition.WorldLocation, FLinearColor::White, 1.5, 30000.0, true);
    } 
} 
#endif
