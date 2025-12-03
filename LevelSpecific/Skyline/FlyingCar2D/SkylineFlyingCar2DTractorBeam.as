event void FSkylineFlyingCar2DTractorBeamSignature();

class ASkylineFlyingCar2DTractorBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent BeamMesh;
	default BeamMesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY()
	FSkylineFlyingCar2DTractorBeamSignature OnExplode;

	UPROPERTY(EditAnywhere)
	float Range = 2000.0;

	ASkylineFlyingCar2D TargetFlyingCar2D;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::Players)
		{
			auto PilotComponent = USkylineFlyingCar2DPilotComponent::Get(Player);
			if (PilotComponent != nullptr)
			{
				if (PilotComponent.FlyingCar2D != nullptr)
					TargetFlyingCar2D = PilotComponent.FlyingCar2D;
			}
		}
	
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		BP_OnBladeHit();
		OnExplode.Broadcast();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBladeHit()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TargetFlyingCar2D == nullptr)
		{
			for (auto Player : Game::Players)
			{
				auto PilotComponent = USkylineFlyingCar2DPilotComponent::Get(Player);
				if (PilotComponent != nullptr)
				{
					if (PilotComponent.FlyingCar2D != nullptr)
						TargetFlyingCar2D = PilotComponent.FlyingCar2D;
				}
			}			
		}

//		PrintScaled("Target: " + TargetFlyingCar2D, 0.0, FLinearColor::Green, 3.0);
	
		FVector ToTarget = TargetFlyingCar2D.ActorLocation - ActorLocation;

		if (ToTarget.Size() < Range)
		{
			FQuat Rotation = FQuat::Slerp(Pivot.ComponentQuat, FQuat::MakeFromZ(ToTarget), 10.0 * DeltaSeconds);

			Pivot.SetWorldRotation(Rotation);
			BeamMesh.SetRelativeLocation(FVector(0.0, 0.0, ToTarget.Size()));
			BeamMesh.SetRelativeScale3D(FVector(3.0, 3.0, ToTarget.Size() * 0.01));
			BeamMesh.SetVisibility(true);
		}
		else
			BeamMesh.SetVisibility(false);
	}
}