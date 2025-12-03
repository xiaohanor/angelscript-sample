
const FConsoleVariable AutoAimDebug("Haze.AutoAimDebug", DefaultValue = 0);
const FConsoleVariable AutoAimStrength("Haze.AutoAimStrength", DefaultValue = 1.0);

/**
 * Helper targetable component that handles auto-aim.
 *
 * It is not necessary to use this to implement auto-aim.
 * Auto-aim targets can be any UTargetableComponent.
 */
UCLASS(HideCategories = "Activation Cooking Tags Physics LOD Collision Rendering")
class UAutoAimTargetComponent : UTargetableComponent
{
	default TargetableCategory = n"AutoAim";

	/* Specifies if this is enabled or not, so your can turn it off if, for example, an actor dies but doesn't get removed from the scene */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Auto Aim")
	bool bIsAutoAimEnabled = true;

    /**
	 * You can use this to prioritize this component over others
	 */
	UPROPERTY(EditAnywhere, Category = "Auto Aim|Scoring")
	float ScoreMultiplier = 1.0;

    /* The maximum angle that the auto-aim can modify the original trajectory by.
       Specified in degrees. */
    UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "!bUseVariableAutoAimMaxAngle", EditConditionHides))
    float AutoAimMaxAngle = 3.0;

	/**
	 * If set, the 'AutoAimMaxAngle' will change.
	 * At the 'MinimumDistance' the min 'AutoAimMaxAngleMinDistance' is used
	 * At the 'MaximumDistance' the max 'AutoAimMaxAngleAtMaxDistance' is used
	 */
	UPROPERTY(EditAnywhere, Category = "Auto Aim")
	bool bUseVariableAutoAimMaxAngle = false;
	
	/* The maximum angle that the auto-aim can modify the original trajectory by.
       Specified in degrees. */
	UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "bUseVariableAutoAimMaxAngle", EditConditionHides), DisplayName = "Auto Aim Max Angle at Min Distance")
	float AutoAimMaxAngleMinDistance = 3.0;

	 /* The maximum angle that the auto-aim can modify the original trajectory by.
       Specified in degrees. */
	UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "bUseVariableAutoAimMaxAngle", EditConditionHides))
	float AutoAimMaxAngleAtMaxDistance = 3.0;

	/**
	 * Set a target shape. Hits already within this shape will not have their aim redirected.
	 * Hits outside the shape will be redirected to hit the edge of the shape.
	 */
    UPROPERTY(EditAnywhere, Category = "Auto Aim")
    FHazeShapeSettings TargetShape;

	/**
	 * If the angle from the auto-aim components forward vector to the aim origin is more than a specific angle, then this component is invalid.
	 * Can be a good alternative to collision with the current actor if the collision is causing issues.
	 * Make sure to disable bIgnoreActorCollisionForAimTrace under Advanced if this is the case.
	 */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Forward Angle")
    bool bOnlyValidIfAimOriginIsWithinAngle = false;

	/**
	 * The angle of the aim "cone". If the angle from the auto-aim components forward vector to the aim origin is more than this angle, then this component is invalid.
	 * Specified in degrees. 
	 */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Forward Angle", Meta = (EditCondition = "bOnlyValidIfAimOriginIsWithinAngle", ClampMin="1.0", ClampMax="179.0"))
    float MaxAimAngle = 90.0;

	/* How much weight is assigned to the target distance compared to the auto aim angle. */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Scoring")
    float TargetDistanceWeight = 1.0;

	/* Minimum auto aim distance for this specific point. */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Distance")
    float MinimumDistance = 0.0;

	/* Maximum auto aim distance for this specific point. */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Distance")
    float MaximumDistance = 10000.0;

    UPROPERTY(EditAnywhere, Category = "Auto Aim|Distance")
    bool bDrawMinimumAndMaximumDistance = false;

	/* How much to undershoot the aim trace. Prevents thin colliders from blocking the target. */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Collision Trace")
    float TracePullback = 20.0;

	/* Ignore collision associated with the same actor as the auto-aim component when determining whether aim is occluded. */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Collision Trace")
    bool bIgnoreActorCollisionForAimTrace = true;

	/**
	 * Ignore collision with specific components on this actor when determining whether aim is occluded.
	 * Only available when bIgnoreActorCollisionForAimTrace is false, since then we are ignoring all components on this actor.
	 */
    UPROPERTY(EditAnywhere, Category = "Auto Aim|Collision Trace", Meta = (EditCondition = "!bIgnoreActorCollisionForAimTrace"))
    TArray<FComponentReference> ComponentsToIgnoreForAimTrace;
	protected TArray<UPrimitiveComponent> IgnoredComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(ComponentsToIgnoreForAimTrace.Num() > 0)
		{
			IgnoredComponents.Reserve(ComponentsToIgnoreForAimTrace.Num());

			for(auto& ComponentToIgnore : ComponentsToIgnoreForAimTrace)
			{
				UPrimitiveComponent IgnoredComponent = Cast<UPrimitiveComponent>(ComponentToIgnore.GetComponent(Owner));
				AddAutoAimTraceIgnoredComponent(IgnoredComponent);
			}
		}
	}

	UFUNCTION(BlueprintPure)
    float CalculateAutoAimMaxAngle(float CurrentDistance) const
	{
		if (!bUseVariableAutoAimMaxAngle)
			return AutoAimMaxAngle * AutoAimStrength.GetFloat();
		const float DistanceAlpha = Math::Clamp(CurrentDistance - MinimumDistance, 0.0, MaximumDistance) / (MaximumDistance - MinimumDistance);
		return Math::Lerp(AutoAimMaxAngleMinDistance, AutoAimMaxAngleAtMaxDistance, DistanceAlpha) * AutoAimStrength.GetFloat();
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Bail if this target is disabled
		if (!bIsAutoAimEnabled)
			return false;

		// Pre-cull based on total distance, this is technically a bit inaccurate with the shape,
		// but max distances are generally so far that it doesn't matter
		float BaseDistanceSQ = WorldLocation.DistSquared(Query.AimRay.Origin);
		if (BaseDistanceSQ > Math::Square(MaximumDistance))
			return false;
		if (BaseDistanceSQ < Math::Square(MinimumDistance))
			return false;

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.AimRay.Origin - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if(Angle > MaxAimAngle)
				return false;
		}

		// Check if we are actually inside the auto-aim arc
		FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);

		// Cull the minimum distance again, since it's likely we're closer to the shape than to the origin
		Query.DistanceToTargetable = TargetLocation.Distance(Query.AimRay.Origin);
		if (Query.DistanceToTargetable < MinimumDistance)
			return false;

		// Auto aim angle can change based on distance
		float MaxAngle = CalculateAutoAimMaxAngle(Query.DistanceToTargetable);

#if !RELEASE
		// Show debugging for auto-aim if we want to
		ShowDebug(Query.Player, MaxAngle, Query.DistanceToTargetable);
#endif

		FVector TargetDirection = (TargetLocation - Query.AimRay.Origin).GetSafeNormal();
		float AngularBend = Math::RadiansToDegrees(Query.AimRay.Direction.AngularDistanceForNormals(TargetDirection));

		if (AngularBend > MaxAngle)
		{
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			return true;
		}

		// Score the distance based on how much we have to bend the aim
		Query.Result.Score = (1.0 - (AngularBend / MaxAngle));
		Query.Result.Score /= Math::Pow(Math::Max(Query.DistanceToTargetable, 0.01) / 1000.0, TargetDistanceWeight);

		// Apply bonus to score
		Query.Result.Score *= ScoreMultiplier;

		// If the point is occluded we can't target it,
		// we only do this test if we would otherwise become primary target (performance)
		if (Query.IsCurrentScoreViableForPrimary())
		{
			Targetable::MarkVisibilityHandled(Query);
			return CheckPrimaryOcclusion(Query, TargetLocation);
		}

		return true;
	}

	FVector GetAutoAimTargetPointForRay(FAimingRay Ray, bool bConstrainToPlane = true) const
	{
		FVector TargetLocation;

		// If we have a shape, bend to the edge of the shape
		if (!TargetShape.IsZeroSize())
		{
			FTransform TransformNoScale = FTransform(ComponentQuat, WorldLocation);
			TargetLocation = TargetShape.GetClosestPointToLine(
				TransformNoScale,
				Ray.Origin, Ray.Direction
			);
		}
		else
		{
			TargetLocation = GetWorldLocation();
		}

		// If we have a 2D constraint, project it to that plane
		if (bConstrainToPlane
		&& Ray.HasConstraintPlane())
			TargetLocation = TargetLocation.PointPlaneProject(Ray.Origin, Ray.ConstraintPlaneNormal);

		return TargetLocation;
	}

	bool CheckPrimaryOcclusion(FTargetableQuery& Query, FVector TargetLocation) const
	{
		Targetable::RequireAimToPointNotOccluded(Query, TargetLocation, IgnoredComponents, TracePullback, bIgnoreActorCollisionForAimTrace);
		return true;
	}

	void AddAutoAimTraceIgnoredComponent(UPrimitiveComponent IgnoredComponent)
	{
		if(IgnoredComponent == nullptr)
			return;

		IgnoredComponents.AddUnique(IgnoredComponent);
	}

	void RemoveAutoAimTraceIgnoredComponent(UPrimitiveComponent IgnoredComponent)
	{
		if(IgnoredComponent == nullptr)
			return;
		
		IgnoredComponents.RemoveSingleSwap(IgnoredComponent);
	}

#if !RELEASE
   	void ShowDebug(AHazePlayerCharacter FromPlayer, float CalculatedMaxAngle, float Distance) const
    {
        if (AutoAimDebug.GetInt() == 0)
            return;

		if (bIsAutoAimEnabled == false)
			return;

        if (FromPlayer == nullptr)
            return;

		if(!FromPlayer.HasControl())
			return;

        float Radius = Math::Tan(Math::DegreesToRadians(CalculatedMaxAngle)) * Distance;
		if (!TargetShape.IsZeroSize())
		{
			Radius += TargetShape.GetEncapsulatingSphereRadius();
			Debug::DrawDebugShape(
				TargetShape.GetCollisionShape(), WorldLocation, WorldRotation,
				FLinearColor::Green
			);
		}

        Debug::DrawDebugSphere(WorldLocation, Radius, LineColor = FLinearColor::Blue);
    }
#endif
};