const FLinearColor UniformScaledColor(0.1, 1.0, 0.1);
const FLinearColor NonUniformScaledColor(1.0, 0.1, 0.1);

class UVisualizeNonUniformScale
{
	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
	{
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
		if (StaticMeshComponent != nullptr)
		{
			FVector Scale = StaticMeshComponent.GetWorldScale();
			float MinScale = Math::Min(Math::Min(Scale.X, Scale.Y), Scale.Z);
			float MaxScale = Math::Max(Math::Max(Scale.X, Scale.Y), Scale.Z);
			OutColor = Math::Lerp(NonUniformScaledColor, UniformScaledColor, MinScale / MaxScale);
			return true;
		}
		
		return false;
	}
}