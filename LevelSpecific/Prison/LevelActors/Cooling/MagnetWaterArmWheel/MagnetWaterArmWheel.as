#if !RELEASE
namespace DevToggleCooling
{
	const FHazeDevToggleBool DrawMagnetWaterArmWheelSockets;
};
#endif

struct FMagnetWaterArmWheelSocketData
{
	UDroneMagneticSocketComponent SocketComp;
	bool bIsDisabled = false;
};

UCLASS(Abstract)
class AMagnetWaterArmWheel : AKineticRotatingActor
{
	default bDisablePlatformMesh = true;
	default NetworkMode = EKineticRotatingNetwork::SyncedFromZoeControl;

	TArray<FMagnetWaterArmWheelSocketData> Sockets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FindSockets();
		UpdateSockets();

#if !RELEASE
		DevToggleCooling::DrawMagnetWaterArmWheelSockets.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		UpdateSockets();

#if !RELEASE
		if(DevToggleCooling::DrawMagnetWaterArmWheelSockets.IsEnabled())
			DrawSockets();
#endif
	}

	private void FindSockets()
	{
		Sockets.Reset(4);

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for(auto AttachedActor : AttachedActors)
		{
			auto SocketComp = UDroneMagneticSocketComponent::Get(AttachedActor);
			if(SocketComp == nullptr)
				continue;

			FMagnetWaterArmWheelSocketData SocketData;
			SocketData.SocketComp = SocketComp;
			SocketData.bIsDisabled = false;
			Sockets.Add(SocketData);
		}
	}

	private void UpdateSockets()
	{
		for(FMagnetWaterArmWheelSocketData& SocketData : Sockets)
		{
			if(SocketData.SocketComp.ForwardVector.Z < -0.2)
			{
				if(!SocketData.bIsDisabled)
				{
					SocketData.SocketComp.Disable(this);
					SocketData.bIsDisabled = true;
				}
			}
			else
			{
				if(SocketData.bIsDisabled)
				{
					SocketData.SocketComp.Enable(this);
					SocketData.bIsDisabled = false;
				}
			}
		}
	}

#if !RELEASE
	private void DrawSockets()
	{
		for(auto SocketData : Sockets)
		{
			if(SocketData.bIsDisabled)
				Debug::DrawDebugString(SocketData.SocketComp.WorldLocation, "Disabled", FLinearColor::Red);
			else
				Debug::DrawDebugString(SocketData.SocketComp.WorldLocation, "Enabled", FLinearColor::Green);
		}
	}
#endif
};