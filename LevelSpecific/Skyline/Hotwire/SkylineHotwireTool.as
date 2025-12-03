event void FSkylineHotwireToolSignature(ASkylineHotwireTool Tool);

class ASkylineHotwireTool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	float AngleSpeed = 0.0;

	AHazePlayerCharacter User;

	FSkylineHotwireToolSignature OnConnect;
	FSkylineHotwireToolSignature OnDisconnect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	
	}

	void Connect()
	{
		BP_Connect();
		OnConnect.Broadcast(this);
	}

	void Disconnect()
	{
		BP_Disconnect();
		OnDisconnect.Broadcast(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Connect() { }

	UFUNCTION(BlueprintEvent)
	void BP_Disconnect() { }
};