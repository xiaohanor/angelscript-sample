event void FSkylineTorTelegraphLightComponentOnToggleSignature();

class USkylineTorTelegraphLightComponent : UActorComponent
{
	private bool _bEnabled;
	FVector TelegraphLocation;

	FSkylineTorTelegraphLightComponentOnToggleSignature OnStart;
	FSkylineTorTelegraphLightComponentOnToggleSignature OnStop;

	bool GetbEnabled() property
	{
		return _bEnabled;
	}

	void Start(FVector Location)
	{
		_bEnabled = true;
		TelegraphLocation = Location;
		OnStart.Broadcast();
	}

	void Update(FVector Location)
	{
		TelegraphLocation = Location;
	}

	void Stop()
	{
		_bEnabled = false;
		OnStop.Broadcast();
	}
}