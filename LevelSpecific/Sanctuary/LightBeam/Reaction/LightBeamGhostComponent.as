
class ULightBeamGhostComponent : UActorComponent
{
	UPROPERTY()
	UMaterialInterface Material;

	UMaterialInstanceDynamic MID;

	ULightBeamResponseComponent LightBeamResponseComponent;

	UPROPERTY(EditAnywhere)
	FLinearColor DisabledColor;

	UPROPERTY(EditAnywhere)
	FLinearColor EnabledColor;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;

	UPROPERTY(EditAnywhere)
	float AnimationSpeed = 1.0;

	TArray<UPrimitiveComponent> Primitives;
	TArray<UTargetableComponent> TargetableComponents;

	FName ColorParameterName = n"BaseColor";
	FName OpacityParameterName = n"Opacity";
	FName EmissiveParameterName = n"EmissiveColor";

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MID = Material::CreateDynamicMaterialInstance(this, Material);
	
//		DisabledColor = MID.GetVectorParameterValue(ColorParameterName);

		UpdatePrimitives();
		UpdateMaterials(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, Material);

		LightBeamResponseComponent = ULightBeamResponseComponent::GetOrCreate(Owner);

		LightBeamResponseComponent.OnHitBegin.AddUFunction(this, n"OnBeamHitStart");
		LightBeamResponseComponent.OnHitEnd.AddUFunction(this, n"OnBeamHitEnd");
	
		Animation.BindUpdate(this, n"OnAnimationUpdate");
		Animation.BindFinished(this, n"OnAnimationFinished");

		Primitives.Reset();
		Owner.GetComponentsByClass(Primitives);

		Owner.GetComponentsByClass(TargetableComponents);

		for (auto TargetableComponent : TargetableComponents)
			TargetableComponent.Disable(this);

		UpdatePrimitives();
		UpdateMaterials(0.0);
		SetCollisionEnabled(false);
	
		Animation.PlayRate = 1.0 / AnimationSpeed;
	}

	UFUNCTION()
	private void OnBeamHitStart(AHazePlayerCharacter Instigator)
	{
		Animation.Play();

		for (auto TargetableComponent : TargetableComponents)
			TargetableComponent.Enable(this);
	}

	UFUNCTION()
	private void OnBeamHitEnd(AHazePlayerCharacter Instigator)
	{
		Animation.Reverse();

		for (auto TargetableComponent : TargetableComponents)
			TargetableComponent.Disable(this);
	}

	UFUNCTION()
	private void OnAnimationUpdate(float Value)
	{
		UpdateMaterials(Value);
	}

	UFUNCTION()
	private void OnAnimationFinished()
	{
		SetCollisionEnabled(!Animation.IsReversed());
	}

	void UpdatePrimitives()
	{
		Primitives.Reset();
		Owner.GetComponentsByClass(Primitives);

		for (auto Primitive : Primitives)
		{
			for (int i = 0; i < Primitive.NumMaterials; i++)
				Primitive.SetMaterial(i, MID);
		}		
	}

	void UpdateMaterials(float Alpha)
	{
		FLinearColor Color = Math::Lerp(DisabledColor, EnabledColor, Alpha);
		float Opacity = Math::Lerp(0.5, 1.0, Alpha);
		MID.SetVectorParameterValue(ColorParameterName, Color);
		MID.SetScalarParameterValue(OpacityParameterName, Opacity);
	}

	void SetCollisionEnabled(bool bCollisionEnabled)
	{
		for (auto Primitive : Primitives)
		{
			Primitive.SetCollisionResponseToAllChannels((bCollisionEnabled ? ECollisionResponse::ECR_Block : ECollisionResponse::ECR_Ignore));
			Primitive.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
			Primitive.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Ignore);
		}
	}
}