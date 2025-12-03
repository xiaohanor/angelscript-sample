
event void FSandHandEvent(FSandHandHitData HitData);

// Generic response component for everything earth hand
class USandHandResponseComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bAffectFauxPhysics = false;

	UPROPERTY(EditAnywhere, Category = "Faux Physics", Meta = (EditCondition = "bAffectFauxPhysics"))
	float ImpulseMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Category = "Sand Hand Response Component")
	FVector CollisionExtents = FVector(40.0);
	FHazeShapeSettings CollisionSettings;
	default CollisionSettings.Type = EHazeShapeType::Box;

	UPROPERTY(Meta = (BPCannotCallEvent))
	FSandHandEvent OnSandHandHitEvent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CollisionSettings.BoxExtents = CollisionExtents;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnSandHandHitEvent.AddUFunction(this, n"OnSandHandHit");

		CollisionSettings.BoxExtents = CollisionExtents;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSandHandHit(FSandHandHitData HitData)
	{
		if (bAffectFauxPhysics)
			FauxPhysics::ApplyFauxImpulseToActorAt(Owner, HitData.RelativeImpactLocation, -HitData.RelativeImpactNormal * SandHand::ImpactForce * ImpulseMultiplier);
	}
}

class USandHandResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USandHandResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USandHandResponseComponent SandHandResponseComponent = Cast<USandHandResponseComponent>(Component);
		if (SandHandResponseComponent == nullptr)
			return;

		// Draw collider
		FLinearColor DrawDebugColor = FLinearColor::Yellow + FLinearColor::LucBlue * 0.2;
		DrawWireShape(SandHandResponseComponent.CollisionSettings.CollisionShape, SandHandResponseComponent.WorldLocation, SandHandResponseComponent.WorldRotation.Quaternion(), DrawDebugColor, 1.0);
	}
}