#if !RELEASE
namespace DevToggleCooling
{
	const FHazeDevToggleBool DrawMagnetWaterCylinderSurfaces;
};
#endif

struct FMagnetWaterCylinderSurfaceData
{
	AMagnetDroneSurfaceActor Surface;
	bool bIsDisabled = false;
};

UCLASS(Abstract)
class AMagnetWaterCylinder : AKineticRotatingActor
{
	default bDisablePlatformMesh = true;
	default MovementMode = EKineticRotatingMode::AlwaysSpinAround;
	default RotationSpeed = FRotator(-20, 0, 0);
	default NetworkMode = EKineticRotatingNetwork::SyncedFromZoeControl;

	TArray<FMagnetWaterCylinderSurfaceData> MagnetSurfaces;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FindSurfaces();

#if !RELEASE
		DevToggleCooling::DrawMagnetWaterCylinderSurfaces.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		UpdateMagnetSurfaces();

#if !RELEASE
		if(DevToggleCooling::DrawMagnetWaterCylinderSurfaces.IsEnabled())
			DrawSurfaces();
#endif
	}

	private void FindSurfaces()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for(const AActor AttachedActor : AttachedActors)
		{
			auto MagnetSurface = Cast<AMagnetDroneSurfaceActor>(AttachedActor);
			if(MagnetSurface == nullptr)
				continue;

			FMagnetWaterCylinderSurfaceData SurfaceData;
			SurfaceData.Surface = MagnetSurface;
			SurfaceData.bIsDisabled = false;
			MagnetSurfaces.Add(SurfaceData);
		}
	}

	private void UpdateMagnetSurfaces()
	{
		for(FMagnetWaterCylinderSurfaceData& SurfaceData : MagnetSurfaces)
		{
			if(SurfaceData.Surface.ActorForwardVector.Z < -0.3)
			{
				if(!SurfaceData.bIsDisabled)
				{
					SurfaceData.Surface.AutoAimComp.Disable(this);
					SurfaceData.bIsDisabled = true;
				}
			}
			else
			{
				if(SurfaceData.bIsDisabled)
				{
					SurfaceData.Surface.AutoAimComp.Enable(this);
					SurfaceData.bIsDisabled = false;
				}
			}
		}
	}

#if !RELEASE
	private void DrawSurfaces()
	{
		for(auto SurfaceData : MagnetSurfaces)
		{
			if(SurfaceData.bIsDisabled)
				Debug::DrawDebugString(SurfaceData.Surface.ActorLocation, "Disabled", FLinearColor::Red);
			else
				Debug::DrawDebugString(SurfaceData.Surface.ActorLocation, "Enabled", FLinearColor::Green);
		}
	}
#endif
};