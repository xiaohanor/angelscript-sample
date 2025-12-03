namespace FlyingCarRifle
{
	void AddHitMarker(USkylineFlyingCarGunnerComponent GunnerComponent, const FHitResult HitResult)
	{
		UFlyingCarRifleHitMarkerWidget HitMarkerWidget = Cast<UFlyingCarRifleHitMarkerWidget>(GunnerComponent.PlayerOwner.AddWidget(GunnerComponent.RifleWidgetData.HitMarkerWidget));
		HitMarkerWidget.Setup(HitResult);
		GunnerComponent.ActiveRifleHitMarkers.Add(HitMarkerWidget);
	}
}

class USkylineFlyineCarRifleHitMarkerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	USkylineFlyingCarGunnerComponent GunnerComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GunnerComponent == nullptr)
			return false;

		if (GunnerComponent.ActiveRifleHitMarkers.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GunnerComponent == nullptr)
			return true;

		if (GunnerComponent.ActiveRifleHitMarkers.IsEmpty())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (int i = GunnerComponent.ActiveRifleHitMarkers.Num() - 1; i >= 0; i--)
		{
			UFlyingCarRifleHitMarkerWidget HitMarker = GunnerComponent.ActiveRifleHitMarkers[i];
			if (HitMarker.IsDuePwnage())
			{
				Player.RemoveWidget(HitMarker);
				GunnerComponent.ActiveRifleHitMarkers.RemoveAt(i);
			}
		}
	}
}