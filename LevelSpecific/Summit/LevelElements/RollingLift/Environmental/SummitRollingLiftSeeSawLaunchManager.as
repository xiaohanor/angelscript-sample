class USummitRollingLiftSeeSawLaunchManagerComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazeShapeSettings ObjectGrabbingZone;

	default ObjectGrabbingZone.Type = EHazeShapeType::Sphere;
	default ObjectGrabbingZone.SphereRadius = 2000;
}

class ASummitRollingLiftSeeSawLaunchManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitRollingLiftSeeSawLaunchManagerComponent ManagerComp;

	UPROPERTY(DefaultComponent)
	USceneComponent SmashapultLandLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent RollingLiftLandLocation;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitRollingLiftSeeSaw SeeSaw;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AAISummitSmashapult SmashapultToLaunch;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitNightQueenGem GemToStartSequence;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AStaticMeshActor> ObjectsToDropAfterSmashing;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SeeSawPunchForce = 1000.0;

	bool bSmashapultLaunched = false;
	bool bSeeSawPunched = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(GemToStartSequence != nullptr, f"{this} has no Gem to start the sequence");
		GemToStartSequence.OnSummitGemDestroyed.AddUFunction(this, n"OnGemSmashed");

		SmashapultLandLocation.AttachToComponent(SeeSaw.AxisRotateComp, n"None", EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSmashapultLaunched && !bSeeSawPunched)
		{
			if(SmashapultToLaunch.ActorLocation.DistSquared(SmashapultLandLocation.WorldLocation) < Math::Square(1000))
			{
				FVector Impulse = -SmashapultLandLocation.UpVector * SeeSawPunchForce;
				SeeSaw.GetPunched(SmashapultToLaunch, Impulse);
				bSeeSawPunched = true;

				auto LiftComp = USummitTeenDragonRollingLiftComponent::Get(Game::GetZoe());
				LiftComp.LaunchLocation.Set(RollingLiftLandLocation.WorldLocation);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGemSmashed(ASummitNightQueenGem CrystalDestroyed)
	{
		StartDroppingObjects();
		LaunchSmashapult();
	}

	void StartDroppingObjects()
	{
		for(auto Object : ObjectsToDropAfterSmashing)
		{
			Object.StaticMeshComponent.SimulatePhysics = true;
		}
	}

	void LaunchSmashapult()
	{
		auto SmashapultComp = USummitSmashapultComponent::Get(SmashapultToLaunch);
		SmashapultComp.LaunchTarget.Set(SmashapultLandLocation.WorldLocation);

		bSmashapultLaunched = true;
	}
#if EDITOR
	UFUNCTION(CallInEditor, Category = "Setup")
	void FetchObjectsToDropAfterSmashing()
	{
		TArray<AStaticMeshActor> StaticMeshActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(AStaticMeshActor);

		for(auto Actor : StaticMeshActorsInLevel)
		{
			if(ManagerComp.ObjectGrabbingZone.IsPointInside(ManagerComp.WorldTransform, Actor.ActorLocation))
			{
				ObjectsToDropAfterSmashing.AddUnique(Cast<AStaticMeshActor>(Actor));
			}
		}
	}
#endif
};

#if EDITOR
class USummitRollingLiftSeeSawLaunchManagerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRollingLiftSeeSawLaunchManagerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRollingLiftSeeSawLaunchManagerComponent>(Component);
		if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		auto Manager = Cast<ASummitRollingLiftSeeSawLaunchManager>(Comp.Owner);

		SetRenderForeground(true);
		VisualizeShape(Comp, Comp.ObjectGrabbingZone);
		VisualizeObjectsToFall(Manager);
	}

	void VisualizeShape(USummitRollingLiftSeeSawLaunchManagerComponent Comp, FHazeShapeSettings Shape)
    {
		const float Thickness = 5.0;

        switch (Shape.Type)
        {
            case EHazeShapeType::Box:
                DrawWireBox(Comp.WorldLocation, Shape.BoxExtents, Comp.WorldRotation.Quaternion(), FLinearColor::Red, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Sphere:
                DrawWireSphere(Comp.WorldLocation, Shape.SphereRadius, FLinearColor::Red, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Capsule:
                DrawWireCapsule(Comp.WorldLocation, Comp.WorldRotation, FLinearColor::Red, Shape.CapsuleRadius, Shape.CapsuleHalfHeight, Thickness, bScreenSpace = false);
            break;
			default: break;
        }
    }

	void VisualizeObjectsToFall(ASummitRollingLiftSeeSawLaunchManager Manager)
	{
		for(auto Object : Manager.ObjectsToDropAfterSmashing)
		{
			if(Object == nullptr)
				continue;
			DrawArrow(Object.ActorLocation + FVector::UpVector * 20, Object.ActorLocation + FVector::DownVector * 20, FLinearColor::Blue, 20, 10, false);
		}
	}
}
#endif