struct FWindArrowAttachedDeactivatedParams
{
	bool bShouldDespawn = false;
}

class UWindArrowAttachedCapability : UHazeCapability
{
	default DebugCategory = WindArrow::DebugCategory;
    default CapabilityTags.Add(WindArrow::WindArrowTag);

    AWindArrow WindArrow;
	UWindArrowResponseComponentContainer ResponseComponentContainer;
	TArray<UWindArrowResponseComponent> ResponseComponentsInWind;
	FHazeAcceleratedQuat AcceleratedQuat;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        WindArrow = Cast<AWindArrow>(Owner);
		ResponseComponentContainer = UWindArrowResponseComponentContainer::GetOrCreate(Game::Mio);
    }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WindArrow.bIsAttached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FWindArrowAttachedDeactivatedParams& Params) const
	{
		if(!WindArrow.bIsAttached)
			return true;

		if(WindArrow.IsAttachedToAnyPlayer() && ActiveDuration > 0.5)
		{
			Params.bShouldDespawn = true;
			return true;
		}

		if(ActiveDuration > 3.0)
		{
			Params.bShouldDespawn = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedQuat.SnapTo(WindArrow.Mesh.ComponentQuat);
		if(WindArrow.IsAttachedToAnyPlayer())
			WindArrow.AttachedToPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWindArrowAttachedDeactivatedParams Params)
	{
		WindArrow.Mesh.RelativeRotation = WindArrow.DefaultRelativeMeshQuat.Rotator();

		if(WindArrow.IsAttachedToAnyPlayer())
			WindArrow.AttachedToPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);

		if(Params.bShouldDespawn)
			WindArrow.WindArrowPlayerComp.RecycleWindArrow(WindArrow);

		for(UWindArrowResponseComponent Response : ResponseComponentsInWind)
		{
			Response.ExitWindZone(WindArrow);
		}

		ResponseComponentsInWind.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat NewQuat = AcceleratedQuat.SpringTo(WindArrow.TargetQuat, 300.0, 0.1, DeltaTime);
		WindArrow.Mesh.ComponentQuat = NewQuat;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(WindArrow.IsAttachedToActor(Player))
				continue;

			if(WindArrow.WindZone.IsPlayerInTrigger(Player))
				Player.AddMovementImpulse(-WindArrow.ActorForwardVector * 5000.0 * DeltaTime);
		}

		for(UWindArrowResponseComponent Response : ResponseComponentContainer.ResponseComponents)
		{
			bool bOverlapping = !WindArrow.IsAttachedToActor(Response.Owner) && IsResponseComponentOverlappingWindZone(Response);
			if(bOverlapping != ResponseComponentsInWind.Contains(Response))
			{
				if(bOverlapping)
				{
					ResponseComponentsInWind.Add(Response);
					Response.EnterWindZone(WindArrow);
				}
				else
				{
					ResponseComponentsInWind.RemoveSingleSwap(Response);
					Response.ExitWindZone(WindArrow);
				}
			}
		}

		if(IsDebugActive())
			Debug::DrawDebugShape(WindArrow.WindZone.Shape.CollisionShape, WindArrow.WindZone.WorldLocation, WindArrow.WindZone.WorldRotation, FLinearColor::Yellow, 3.0);
	}

	bool IsResponseComponentOverlappingWindZone(UWindArrowResponseComponent Response)
	{
		FCollisionShape ResponseShape;
		FTransform ResponseTransform;
		if(Response.bHitAnywhere)
		{
			FBox Bounds = Response.Owner.GetActorLocalBoundingBox(true);
			ResponseShape = FCollisionShape::MakeBox(Bounds.Extent);
			ResponseTransform = Response.Owner.ActorTransform;
			ResponseTransform.Location = ResponseTransform.Location + Response.Owner.ActorTransform.TransformVector(Bounds.Center);
		}
		else
		{
			ResponseShape = Response.CollisionSettings.CollisionShape;
			ResponseTransform = Response.WorldTransform;
		}

		return Overlap::QueryShapeOverlap(ResponseShape, ResponseTransform, WindArrow.WindZone.Shape.CollisionShape, WindArrow.WindZone.WorldTransform);
	}
}