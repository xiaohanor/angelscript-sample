UCLASS(NotBlueprintable, NotPlaceable)
class UPrisonStealthCardboardBoxPlayerComponent : UActorComponent
{
	private APrisonStealthCardboardBox CardboardBox = nullptr;

	// Tracking for VO
	private bool bEvadedDetection = false;

	void OnCardboardBoxAttached(APrisonStealthCardboardBox InCardboardBox)
	{
		CardboardBox = InCardboardBox;
	}

	void OnCardboardBoxDetached()
	{
		CardboardBox = nullptr;
		bEvadedDetection = false;
	}

	bool HasCardboardBox() const
	{
		return CardboardBox != nullptr;
	}

	void OnEvadedDetection(bool bEvaded) 
	{
		bEvadedDetection = bEvaded;
	}

	bool HasEvadedDetection() const
	{
		return bEvadedDetection;
	}
};