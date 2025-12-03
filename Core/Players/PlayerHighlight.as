UCLASS(Abstract)
class APlayerHighlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USpotLightComponent SpotLightComp;
	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLightComp;
	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphereComp;

	UPlayerHighlightSettings Settings;
	AHazePlayerCharacter Player;

	bool bFadingOut = false;
	float Opacity = 0.0;
	int AppliedModificationId = -1;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFadingOut)
		{
			Opacity = Math::FInterpConstantTo(Opacity, 0.0, DeltaSeconds, 1.0);
			UpdateOpacity(Opacity);
			if (Opacity <= 0.0)
			{
				bFadingOut = false;
				DestroyActor();
			}
		}
		else if (Opacity != 1.0)
		{
			Opacity = Math::FInterpConstantTo(Opacity, 1.0, DeltaSeconds, 1.0);
			UpdateOpacity(Opacity);
		}

		if (AppliedModificationId != Settings.ModificationId)
		{
			UpdateAllSettings();
			UpdateOpacity(Opacity);
		}
	}

	void Initialize()
	{
		UpdateAllSettings();
		UpdateOpacity(0.0);
	}

	void UpdateAllSettings()
	{
		PointLightComp.SetLightColor(Settings.HighlightColor[Player]);
		PointLightComp.SetRelativeLocation(Settings.PointLightRelativeOffset);
		PointLightComp.SetAttenuationRadius(Settings.PointlightAttenuationRadius);

		HazeSphereComp.SetColor(HazeSphereComp.Opacity, HazeSphereComp.Softness, Settings.HighlightColor[Player]);
		HazeSphereComp.SetRelativeLocation(Settings.HazeSphereRelativeOffset);
		HazeSphereComp.SetWorldScale3D(FVector(Settings.HazeSphereRadius / 100.0));
		HazeSphereComp.UpdateScale();

		if (Settings.SpotlightColorOverride[Player].A != 0)
			SpotLightComp.SetLightColor(Settings.SpotlightColorOverride[Player]);
		else
			SpotLightComp.SetLightColor(Settings.HighlightColor[Player]);

		SpotLightComp.SetAttenuationRadius(Settings.SpotlightAttenuationRadius);
		AppliedModificationId = Settings.ModificationId;

		if ((Settings.SpotlightIntensity != 0 && !Settings.bSpotlightAffectsWorld) || (Settings.PointlightIntensity != 0 && !Settings.bPointlightAffectsWorld))
		{
			auto Mesh = Player.FindRelevantAttachMeshForNiagara();
			Mesh.SetLightingChannels(true, Player.IsMio(), Player.IsZoe());
			if (Mesh != Player.Mesh)
				Player.Mesh.SetLightingChannels(true, Player.IsMio(), Player.IsZoe());
		}
		else
		{
			auto Mesh = Player.FindRelevantAttachMeshForNiagara();
			Mesh.SetLightingChannels(true, false, false);
			if (Mesh != Player.Mesh)
				Player.Mesh.SetLightingChannels(true, false, false);
		}

		if (Settings.SpotlightIntensity != 0 && !Settings.bSpotlightAffectsWorld)
			SpotLightComp.SetLightingChannels(false, Player.IsMio(), Player.IsZoe());
		else
			SpotLightComp.SetLightingChannels(true, false, false);

		if (Settings.PointlightIntensity != 0 && !Settings.bPointlightAffectsWorld)
			PointLightComp.SetLightingChannels(false, Player.IsMio(), Player.IsZoe());
		else
			PointLightComp.SetLightingChannels(true, false, false);
	}

	void UpdateOpacity(float Alpha)
	{
		SpotLightComp.SetIntensity(Settings.SpotlightIntensity * Alpha);
		PointLightComp.SetIntensity(Settings.PointlightIntensity * Alpha);
		HazeSphereComp.SetOpacityValue(Settings.HazeSphereOpacity * Alpha);
	}
};

class UPlayerHighlightSettings : UHazeComposableSettings
{
	UPROPERTY()
	bool bPlayerHighlightVisible = false;
	UPROPERTY()
	TPerPlayer<FLinearColor> HighlightColor;
	default HighlightColor[0] = PlayerColor::Mio;
	default HighlightColor[1] = PlayerColor::Zoe;
	UPROPERTY()
	FName HighlightAttachSocket = n"Hips";
	UPROPERTY(Category = "Spot Light")
	float SpotlightIntensity = 0.0;
	UPROPERTY(Category = "Spot Light")
	float SpotlightDistance = 200.0;
	UPROPERTY(Category = "Spot Light")
	float SpotlightAttenuationRadius = 400.0;
	UPROPERTY(Category = "Spot Light")
	FRotator SpotlightAngle;
	UPROPERTY(Category = "Spot Light")
	FVector SpotlightAttachOffset(0, 0, 0);
	UPROPERTY(Category = "Spot Light")
	bool bSpotlightAffectsWorld = true;
	UPROPERTY(Category = "Spot Light")
	TPerPlayer<FLinearColor> SpotlightColorOverride;
	default SpotlightColorOverride[0] = FLinearColor::Transparent;
	default SpotlightColorOverride[1] = FLinearColor::Transparent;
	UPROPERTY(Category = "Point Light")
	float PointlightIntensity = 0.0;
	UPROPERTY(Category = "Point Light")
	float PointlightAttenuationRadius = 410;
	UPROPERTY(Category = "Point Light")
	FVector PointLightRelativeOffset(0, 0, 0);
	UPROPERTY(Category = "Point Light")
	bool bPointlightAffectsWorld = true;
	UPROPERTY(Category = "Haze Sphere")
	float HazeSphereOpacity = 0.0;
	UPROPERTY(Category = "Haze Sphere")
	float HazeSphereRadius = 100.0;
	UPROPERTY(Category = "Haze Sphere")
	FVector HazeSphereRelativeOffset(0, 0, 0);
	UPROPERTY()
	TSubclassOf<APlayerHighlight> HighlightClass;
}

class UPlayerHighlightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PlayerHighlight");
	default CapabilityTags.Add(n"BlockedByCutscene");

	UPlayerHighlightSettings Settings;
	APlayerHighlight Highlight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UPlayerHighlightSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Settings.bPlayerHighlightVisible)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Settings.bPlayerHighlightVisible)
			return true;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Highlight = SpawnActor(Settings.HighlightClass);
		Highlight.Player = Player;
		Highlight.Settings = Settings;
		Highlight.Initialize();

		Highlight.AttachToComponent(Player.FindRelevantAttachMeshForNiagara(), Settings.HighlightAttachSocket);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Highlight.bFadingOut = true;
		Highlight = nullptr;

		if ((Settings.SpotlightIntensity != 0 && !Settings.bSpotlightAffectsWorld) || (Settings.PointlightIntensity != 0 && !Settings.bPointlightAffectsWorld))
		{
			auto Mesh = Player.FindRelevantAttachMeshForNiagara();
			Mesh.SetLightingChannels(true, false, false);
			if (Mesh != Player.Mesh)
				Player.Mesh.SetLightingChannels(true, false, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Settings.SpotlightIntensity > 0)
		{
			FQuat SpotlightRotation = Player.ViewRotation.Quaternion() * Settings.SpotlightAngle.Quaternion();
			Highlight.SpotLightComp.SetWorldLocationAndRotation(
				Highlight.ActorLocation
					- SpotlightRotation.ForwardVector * Settings.SpotlightDistance
					+ Player.ActorTransform.TransformVector(Settings.SpotlightAttachOffset),
				SpotlightRotation);
		}
	}
}