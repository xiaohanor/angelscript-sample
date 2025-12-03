event void FSummitDarkCaveGongSignature();

class ASummitDarkCaveGong : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent GongRotateComp;
	default GongRotateComp.LocalRotationAxis = FVector(0, 1.0, 0.0);
	default GongRotateComp.SpringStrength = 10.0;

	UPROPERTY(DefaultComponent, Attach = GongRotateComp)
	UStaticMeshComponent GongMeshComp;

	UPROPERTY(DefaultComponent, Attach = GongMeshComp)
	UTeenDragonTailAttackResponseComponent RollResponseComp;
	default RollResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	USceneComponent ShapeRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitDarkCaveGongDummyComponent DummyComp;
#endif
	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem GongSoundEffect;

	UPROPERTY(EditAnywhere, Category = "Shape")
	FHazeShapeSettings Shape;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongImpulse = 500;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongBrazierDelay = 0.5;

	UPROPERTY()
	FSummitDarkCaveGongSignature GongHitByRoll;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRoll(FRollParams Params)
	{
		GongHitByRoll.Broadcast(); // Added by pussel. Available on slack.

		FVector Impulse = Params.RollDirection * GongImpulse;
		FauxPhysics::ApplyFauxImpulseToParentsAt(GongRotateComp, Params.HitLocation, Impulse);

		float ForwardDotPlayerForward = Params.RollDirection.DotProduct(GongMeshComp.ForwardVector);
		FVector TraceForward = ForwardDotPlayerForward > 0 ? GongMeshComp.ForwardVector : -GongMeshComp.ForwardVector;
		FRotator TraceRotation;
		FTransform TraceTransform = ShapeRoot.WorldTransform;
		if(Shape.CollisionShape.IsCapsule())
		{
			TraceRotation = FRotator::MakeFromZ(TraceForward);
			TraceTransform.Location = GongMeshComp.WorldLocation + TraceRotation.UpVector * Shape.CapsuleHalfHeight;
		}
		else
			TraceRotation = FRotator::MakeFromX(TraceForward);

		TraceTransform.Rotation = TraceRotation.Quaternion();

		TListedActors<ASummitDarkCaveAcidBrazier> BraziersInLevel;
		for(auto Brazier : BraziersInLevel)
		{
			if(Shape.IsPointInside(TraceTransform, Brazier.GongHitLocation.WorldLocation))
				Brazier.HitByGongWave();
		}

		TListedActors<ASummitDarkCaveMetalStatue> StatuesInLevel;
		for(auto Statue : StatuesInLevel)
		{
			if(Shape.IsPointInside(TraceTransform, Statue.GongHitLocation.WorldLocation))
				Statue.HitByGongWave();
		}

		FRotator EffectRotation = FRotator::MakeFromX(TraceForward);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(GongSoundEffect, GongMeshComp.WorldLocation, EffectRotation);
	}
};

#if EDITOR
class USummitDarkCaveGongDummyComponent : UActorComponent {};
class USummitDarkCaveGongComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitDarkCaveGongDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitDarkCaveGongDummyComponent>(Component);
		if(Comp == nullptr)
			return;
		
		auto Gong = Cast<ASummitDarkCaveGong>(Component.Owner);
		if(Gong == nullptr)
			return;

		if(Gong.Shape.CollisionShape.IsBox())
			DrawWireBox(Gong.ShapeRoot.WorldLocation, Gong.Shape.BoxExtents, Gong.ShapeRoot.ComponentQuat, FLinearColor::LucBlue, 20, false);
		else if(Gong.Shape.CollisionShape.IsSphere())
			DrawWireSphere(Gong.ShapeRoot.WorldLocation, Gong.Shape.SphereRadius, FLinearColor::LucBlue, 20, 24, false);
		else if(Gong.Shape.CollisionShape.IsCapsule())
			DrawWireCapsule(Gong.ShapeRoot.WorldLocation - Gong.GongMeshComp.ForwardVector * Gong.Shape.CapsuleHalfHeight
				, FRotator::MakeFromZ(Gong.ShapeRoot.ForwardVector), FLinearColor::LucBlue, Gong.Shape.CapsuleRadius, Gong.Shape.CapsuleHalfHeight, 12, 20, false);

	}
}
#endif