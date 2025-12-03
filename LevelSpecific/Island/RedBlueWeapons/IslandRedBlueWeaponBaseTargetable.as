class UIslandRedBlueWeaponBaseTargetable : UAutoAimTargetComponent
{
	default bUseVariableAutoAimMaxAngle = true;
	default AutoAimMaxAngleMinDistance = 8;
	default AutoAimMaxAngleAtMaxDistance = 4;
	default MaximumDistance = 5000;

	// Targetables will move around in this shape if set.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	FHazeShapeSettings OptionalShape;

	FTransform RelativeShapeTransform;

	// Only used for if there is a shape
	UIslandRedBlueWeaponBaseTargetable ZoeVolumeTargetableComp;
	bool bIsOtherTargetable = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UTargetableOutlineComponent> Outlines;
		Owner.GetComponentsByClass(Outlines);

		for(int i = Outlines.Num() - 1; i >= 0; i--)
		{
			if(Outlines[i].ComponentCreationMethod != EComponentCreationMethod::UserConstructionScript)
				continue;

			Editor::DestroyAndRenameInstanceComponentInEditor(Outlines[i]);
			Outlines.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(!OptionalShape.IsZeroSize())
		{
			RelativeShapeTransform = RelativeTransform;

			if(UsableByPlayers == EHazeSelectPlayer::Both)
			{
				// If this targetable can be targeted by both players and we have a shape we need to copy this component so each player have their own targetable since it is going to move around in the shape.
				ZoeVolumeTargetableComp = Cast<UIslandRedBlueWeaponBaseTargetable>(Owner.CreateComponent(GetClass()));
				ZoeVolumeTargetableComp.AttachToComponent(AttachParent, AttachSocketName);
				ZoeVolumeTargetableComp.RelativeTransform = RelativeTransform;
				ZoeVolumeTargetableComp.CopyScriptPropertiesFrom(this);
				DisableForPlayer(Game::Zoe, IslandForceField::ForceFieldToggleInstigator);
				ZoeVolumeTargetableComp.DisableForPlayer(Game::Mio, IslandForceField::ForceFieldToggleInstigator);
				ZoeVolumeTargetableComp.bIsOtherTargetable = true;
			}
		}
		else
		{
			SetComponentTickEnabled(false);
		}
	}

	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator) override
	{
		Super::DisableForPlayer(Player, Instigator);

		if(IsDisabled())
			SetComponentTickEnabled(false);
		
		if(bIsOtherTargetable)
			return;

		if(OptionalShape.IsZeroSize())
			return;

		if(ZoeVolumeTargetableComp == nullptr)
			return;

		if(UsableByPlayers == EHazeSelectPlayer::None
		|| UsableByPlayers == EHazeSelectPlayer::Mio)
		{
			if(!ZoeVolumeTargetableComp.IsDisabledForPlayer(Player))
			{
				ZoeVolumeTargetableComp.DisableForPlayer(Player, Instigator);
			}
		}
	}

	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator) override
	{
		Super::EnableForPlayer(Player, Instigator);

		if(!IsDisabled() && !OptionalShape.IsZeroSize())
			SetComponentTickEnabled(true);

		if(bIsOtherTargetable)
			return;

		if(OptionalShape.IsZeroSize())
			return;

		if(ZoeVolumeTargetableComp == nullptr)
			return;

		if(UsableByPlayers == EHazeSelectPlayer::Zoe
		|| UsableByPlayers == EHazeSelectPlayer::Both)
		{
			if(ZoeVolumeTargetableComp.IsDisabledForPlayer(Player))
			{
				ZoeVolumeTargetableComp.EnableForPlayer(Player, Instigator);
			}
		}
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) final
	{
		if(OptionalShape.IsZeroSize())
		{
			SetComponentTickEnabled(false);
			return;
		}

		AHazePlayerCharacter CurrentPlayer = nullptr;

		if(bIsOtherTargetable)
		{
			if(UsableByPlayers == EHazeSelectPlayer::Zoe
			|| UsableByPlayers == EHazeSelectPlayer::Both)
			{
				if(!IsDisabledForPlayer(Game::Zoe))
				{
					CurrentPlayer = Game::Zoe;
				}
			}
		}
		else
		{
			if(UsableByPlayers == EHazeSelectPlayer::Mio
			|| UsableByPlayers == EHazeSelectPlayer::Both)
			{
				if(!IsDisabledForPlayer(Game::Mio))
				{
					CurrentPlayer = Game::Mio;
				}
			}
		}

		if(CurrentPlayer == nullptr)
			return;

		auto AimComp = UPlayerAimingComponent::Get(CurrentPlayer);
		const bool bIsAiming = AimComp.IsAiming();

		if(!bIsAiming)
			return;

		FAimingRay AimRay = AimComp.GetPlayerAimingRay();
		FTransform ShapeWorldTransform = RelativeShapeTransform;
		if(AttachParent != nullptr)
		{
			ShapeWorldTransform *= AttachParent.WorldTransform;
		}

		FVector Location = OptionalShape.GetClosestPointToLine(ShapeWorldTransform, AimRay.Origin, AimRay.Direction);
		WorldLocation = Location;
	}

	/** Implement to offset the location we should be shooting at */
	UFUNCTION(BlueprintEvent)
	FVector GetTargetLocation(AHazePlayerCharacter Player) const
	{
		return GetWorldLocation();
	}

	bool CheckPrimaryOcclusion(FTargetableQuery& Query, FVector TargetLocation) const override
	{
		ModifiedRequireAimToPointNotOccluded(Query, TargetLocation);
		return true;
	}

	// This is a modified version of Targetable::RequireAimToPointNotOccluded, the only difference is that it will line trace multi and ignore force fields if we traced through a hole.
	bool ModifiedRequireAimToPointNotOccluded(FTargetableQuery& Query, FVector TargetPoint) const
	{
		// If we are already invisible and cannot be the primary target, we don't need to trace
		if (!Query.Result.bVisible)
		{
			if (Query.Result.Score <= 0.0 || !Query.IsCurrentScoreViableForPrimary())
				return false;
			if (!Query.Result.bPossibleTarget)
				return false;
		}

		Query.bHasPerformedTrace = true;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming, n"TargetableOcclusion");
		Trace.UseLine();
		Trace.IgnorePlayers();
		Trace.IgnoreCameraHiddenComponents(Query.Player);

		if (bIgnoreActorCollisionForAimTrace)
			Trace.IgnoreActor(Query.Component.Owner);

		if (IgnoredComponents.Num() > 0)
			Trace.IgnoreComponents(IgnoredComponents);

		FVector TargetPosition = TargetPoint;
		if (TracePullback != 0.0)
			TargetPosition -= (TargetPosition - Query.AimRay.Origin).GetSafeNormal() * TracePullback;

		// OL: START MODIFY FUNCTION
		FVector TraceStart = Query.AimRay.Origin;
		FHitResultArray Hits = Trace.QueryTraceMulti(
			TraceStart,
			TargetPosition,
		);

		FHitResult Hit;
		for(FHitResult Current : Hits.BlockHits)
		{
			if(IslandRedBlueWeapon::CurrentCameraWeaponTraceHitIsValid(Query.Player, Current, this))
			{
				Hit = Current;
				break;
			}
		}
		// OL: END MODIFY FUNCTION

		#if EDITOR
		Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireAimToPointNotOccluded", Hit, Trace.Shape, Trace.ShapeWorldOffset));
		#endif

		if (Hit.bBlockingHit)
		{
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return false;
		}
		else
		{
			return true;
		}
	}
}

#if EDITOR
class UIslandRedBlueWeaponBaseTargetableComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandRedBlueWeaponBaseTargetable;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AutoAimVisualizeComponent(Component);

		auto RedBlueTargetable = Cast<UIslandRedBlueWeaponBaseTargetable>(Component);

		if (!RedBlueTargetable.OptionalShape.IsZeroSize())
		{
			switch (RedBlueTargetable.OptionalShape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						RedBlueTargetable.WorldLocation,
						RedBlueTargetable.OptionalShape.BoxExtents * RedBlueTargetable.WorldScale,
						RedBlueTargetable.ComponentQuat,
						FLinearColor::Green,
						2.0
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						RedBlueTargetable.WorldLocation,
						RedBlueTargetable.OptionalShape.SphereRadius,
						FLinearColor::Green,
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						RedBlueTargetable.WorldLocation,
						RedBlueTargetable.WorldRotation,
						FLinearColor::Green,
						RedBlueTargetable.OptionalShape.CapsuleRadius,
						RedBlueTargetable.OptionalShape.CapsuleHalfHeight,
						16, 2.0
					);
				break;
				default:
					devError("Forgot to add case!");
			}
		}
	}

	// This function is a copy of VisualizeComponent in UAutoAimTargetVisualizer
    void AutoAimVisualizeComponent(const UActorComponent Component)
    {
        UAutoAimTargetComponent AimComp = Cast<UAutoAimTargetComponent>(Component);
		
		// happens on teardown on the dummy component
		if(AimComp == nullptr)
			return;

        if (AimComp.GetOwner() == nullptr)
            return;

		DrawPoint(AimComp.WorldLocation, FLinearColor::Green, 20.0);

        FVector EditorCamera = EditorViewLocation;
        float Distance = EditorCamera.Distance(AimComp.WorldLocation);

        float Radius = Math::Tan(Math::DegreesToRadians(AimComp.CalculateAutoAimMaxAngle(Distance))) * Distance;
		if (!AimComp.TargetShape.IsZeroSize())
		{
			Radius += AimComp.TargetShape.GetEncapsulatingSphereRadius();
			switch (AimComp.TargetShape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						AimComp.WorldLocation,
						AimComp.TargetShape.BoxExtents,
						AimComp.ComponentQuat,
						FLinearColor::Green,
						2.0
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						AimComp.WorldLocation,
						AimComp.TargetShape.SphereRadius,
						FLinearColor::Green,
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						AimComp.WorldLocation,
						AimComp.WorldRotation,
						FLinearColor::Green,
						AimComp.TargetShape.CapsuleRadius,
						AimComp.TargetShape.CapsuleHalfHeight,
						16, 2.0
					);
				break;
				default:
					devError("Forgot to add case!");
			}
		}

        DrawWireSphere(AimComp.WorldLocation, Radius, Color = FLinearColor::Blue);

		if(AimComp.bOnlyValidIfAimOriginIsWithinAngle)
		{
			DrawArrow(AimComp.WorldLocation, AimComp.WorldLocation + AimComp.ForwardVector * 100.0, FLinearColor::Red);
			DrawCone(AimComp.WorldLocation, AimComp.ForwardVector, AimComp.MaxAimAngle);
		}

		if(AimComp.bDrawMinimumAndMaximumDistance)
		{
			if(AimComp.MinimumDistance > KINDA_SMALL_NUMBER)
				DrawWireSphere(AimComp.WorldLocation, AimComp.MinimumDistance, FLinearColor::Yellow, 2.0, 24);
			
			DrawWireSphere(AimComp.WorldLocation, AimComp.MaximumDistance, FLinearColor::Red, 5.0, 24);
		}
    }   

	void DrawCone(FVector Origin, FVector Direction, float ConeAngle)
	{
		const float Radius = 250.0;
		float ConeRadians = Math::DegreesToRadians(ConeAngle);

		// Construct perpendicular vector
		FVector P1 = Direction.CrossProduct(Direction.GetAbs().Equals(FVector::UpVector) ? FVector::RightVector : FVector::UpVector);
		P1.Normalize();

		FVector P2 = P1.CrossProduct(Direction);

		// Draw cone sides
		FVector Tip = Direction * Radius;
		FVector TiltedTip = FQuat(P1, ConeRadians) * Tip;
		FVector ConeBase = Direction * Math::Cos(ConeRadians) * Radius;

		float StepRadians = TWO_PI / 10;

		for(int i = 0; i < 10; ++i)
		{
			float Angle = i * StepRadians;
			FVector StepTip = FQuat(Direction, Angle) * TiltedTip;

			DrawDashedLine(Origin, Origin + StepTip, FLinearColor::Gray);
		}

		// Draw tip circle
		DrawCircle(Origin + ConeBase, Math::Sin(ConeRadians) * Radius, FLinearColor::Yellow, 2.0, Direction);

		// Draw rotational arcs
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, FLinearColor::Yellow, 2.0, P1, bDrawSides = false);
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, FLinearColor::Yellow, 2.0, P2, bDrawSides = false);
	}
}
#endif