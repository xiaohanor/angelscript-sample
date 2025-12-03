enum EJetskiSplineDiveZoneType
{
	AllowDive,
	BlockDive,
	ForceDive,
	BlockAirDive,
};

UCLASS(NotBlueprintable)
class UJetskiSplineDiveZoneComponent : UAlongSplineComponent
{
#if EDITOR
	default EditorColor = FLinearColor::LucBlue;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Jetski Dive Zone")
	EJetskiSplineDiveZoneType ZoneType = EJetskiSplineDiveZoneType::BlockDive;
};

#if EDITOR
class UJetskiSplineDiveZoneComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiSplineDiveZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto DiveZoneComp = Cast<UJetskiSplineDiveZoneComponent>(Component);
		if(DiveZoneComp == nullptr)
			return;
		
		const FString Text = f"{DiveZoneComp.ZoneType:n}";
		const FLinearColor Color = GetColor(DiveZoneComp.ZoneType);
		DrawWorldString(Text, DiveZoneComp.WorldLocation, Color, 1, -1, false, true);
	}

	FLinearColor GetColor(EJetskiSplineDiveZoneType Type) const
	{
		switch(Type)
		{
			case EJetskiSplineDiveZoneType::AllowDive:
				return FLinearColor::Green;

			case EJetskiSplineDiveZoneType::BlockDive:
				return FLinearColor::Red;

			case EJetskiSplineDiveZoneType::ForceDive:
				return FLinearColor::LucBlue;

			case EJetskiSplineDiveZoneType::BlockAirDive:
				return FLinearColor::Purple;
		}
	}
}
#endif