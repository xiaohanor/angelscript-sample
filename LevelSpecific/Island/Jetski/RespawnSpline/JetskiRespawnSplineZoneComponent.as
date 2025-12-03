enum EJetskiRespawnSplineZoneType
{
	AllowRespawn,
	DisallowRespawn,
};

UCLASS(NotBlueprintable)
class UJetskiRespawnSplineZoneComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	EJetskiRespawnSplineZoneType Type;

	bool CanRespawnWithinZone() const
	{
		switch(Type)
		{
			case EJetskiRespawnSplineZoneType::AllowRespawn:
				return true;

			case EJetskiRespawnSplineZoneType::DisallowRespawn:
				return false;
		}
	}

#if EDITOR
	FLinearColor GetVisualizeColor() const
	{
		switch(Type)
		{
			case EJetskiRespawnSplineZoneType::AllowRespawn:
				return FLinearColor::Green;
			
			case EJetskiRespawnSplineZoneType::DisallowRespawn:
				return FLinearColor::Red;
		}
	}

	FString GetVisualName() const
	{
		switch(Type)
		{
			case EJetskiRespawnSplineZoneType::AllowRespawn:
				return "Allow Respawn";

			case EJetskiRespawnSplineZoneType::DisallowRespawn:
				return "Disallow Respawn";
		}
	}
#endif
};

#if EDITOR
class UJetskiRespawnSplineZoneComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiRespawnSplineZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto ZoneComp = Cast<UJetskiRespawnSplineZoneComponent>(Component);
		if(ZoneComp == nullptr)
			return;

		DrawWireBox(
			ZoneComp.WorldLocation,
			FVector(0, 500, 300),
			ZoneComp.ComponentQuat,
			ZoneComp.GetVisualizeColor(),
			3,
			true
		);
	}
};
#endif