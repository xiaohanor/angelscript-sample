event void FSkylinePhoneSignature();

UCLASS(Abstract)
class ASkylinePhoneBase : AHazeActor
{
	bool bPhoneCompleted = false;
	int PhoneGameIndex = -1;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UHazeCrumbSyncedVector2DComponent CursorPosition;

	FVector2D CursorBounds = FVector2D(400.0, 800.0);
	
	FSkylinePhoneSignature OnClickPressed;
	FSkylinePhoneSignature OnClickReleased;

	TOptional<float> XInputSensitivityOverride;
	TOptional<float> YInputSensitivityOverride;
	
	bool bGameStarted = false;
	bool bProgressMadeSinceLastLoad = false;
	
	void MoveCursor(FVector2D Delta)
	{
		float ClampedX = Math::Clamp(CursorPosition.Value.X + Delta.X, -CursorBounds.X, CursorBounds.X);
		float ClampedY = Math::Clamp(CursorPosition.Value.Y - Delta.Y, -CursorBounds.Y, CursorBounds.Y);
		CursorPosition.SetValue(FVector2D(ClampedX, ClampedY));
	}

	void Click()
	{
		CrumbClick(CursorPosition.Value);
	}

	void Release()
	{
		CrumbRelease(CursorPosition.Value);
	}

	UFUNCTION(CrumbFunction)
	void CrumbClick(FVector2D CursorPos)
	{
		OnClickPressed.Broadcast();
		OnClick(CursorPos);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRelease(FVector2D CursorPos)
	{
		OnClickReleased.Broadcast();
		OnRelease(CursorPos);
	}

	void OnClick(FVector2D CursorPos){}
	void OnRelease(FVector2D CursorPos){}
};