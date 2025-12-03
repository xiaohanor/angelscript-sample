// Something with Shadows that causes to make them much more expensive than average,
// Think it is Movable meshes, with Dynamic Shadows, and Shadow Priority that is ... Not background?

class UVisualizeShadowPriority
{
	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
	{
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
		if (StaticMeshComponent != nullptr)
		{
			// Skip StaticMeshComponents that don't cast dynamic shadows
			if (!StaticMeshComponent.CastShadow || !StaticMeshComponent.bCastDynamicShadow)
				return false;
			
			switch(StaticMeshComponent.ShadowPriority) {
				case EShadowPriority::Background:
					OutColor = FLinearColor::Green;
					break;
				case EShadowPriority::GameplayElement:
					OutColor = FLinearColor::Yellow;
					break;
				case EShadowPriority::ImportantShadow:
					OutColor = FLinearColor::Red;
					break;
				default:
					break;
			}
			return true;
		}
		
		return false;
	}
}