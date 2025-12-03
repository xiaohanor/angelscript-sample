/**
 * Contains the current movement contacts
 */
struct FMovementContacts
{
	FMovementHitResult GroundContact;
	FMovementHitResult WallContact;
	FMovementHitResult CeilingContact;
	
	FCustomMovementStatus CustomStatus;

#if !RELEASE
	TArray<FInstigator> GroundContactOverrideInstigators;
	TArray<FInstigator> WallContactOverrideInstigators;
	TArray<FInstigator> CeilingContactOverrideInstigators;
#endif

	bool HasCustomStatus() const
	{
		return CustomStatus.Name != NAME_None;
	}

	bool HasAnyValidBlockingContacts() const
	{
		if(GroundContact.IsAnyGroundContact())
			return true;

		if(WallContact.IsWallImpact())
			return true;

		if(CeilingContact.IsCeilingImpact())
			return true;

		return false;
	}	

	/**
	 * Get the first impact that is valid of any type.
	 * @param Order The priority order used when returning valid contacts.
	 * @return True if a valid contact was found.
	 */
	bool GetAnyValidContact(FMovementHitResult&out OutContact, EMovementAnyContactOrder Order = EMovementAnyContactOrder::GroundWallCeiling) const no_discard
	{
		switch(Order)
		{
			case EMovementAnyContactOrder::GroundWallCeiling:
			{
				if(GetValidContact(EMovementImpactType::Ground, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Wall, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ceiling, OutContact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::GroundCeilingWall:
			{
				if(GetValidContact(EMovementImpactType::Ground, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ceiling, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Wall, OutContact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::WallGroundCeiling:
			{
				if(GetValidContact(EMovementImpactType::Wall, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ground, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ceiling, OutContact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::WallCeilingGround:
			{
				if(GetValidContact(EMovementImpactType::Wall, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ceiling, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ground, OutContact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::CeilingGroundWall:
			{
				if(GetValidContact(EMovementImpactType::Ceiling, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ground, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Wall, OutContact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::CeilingWallGround:
			{
				if(GetValidContact(EMovementImpactType::Ceiling, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Wall, OutContact))
					return true;
				else if(GetValidContact(EMovementImpactType::Ground, OutContact))
					return true;
				else
					return false;
			}
		}
	}

	/**
	 * Get the contact of ContactType. Only Ground, Wall and Ceiling are valid options.
	 * The contact may be invalid. For a validated version, see GetValidContact()
	 * @see GetValidContact()
	 */
	const FMovementHitResult& GetContact(EMovementImpactType ContactType) const
	{
		switch(ContactType)
		{
			case EMovementImpactType::Ground:
				return GroundContact;

			case EMovementImpactType::Wall:
				return WallContact;

			case EMovementImpactType::Ceiling:
				return CeilingContact;
			
			default:
				check(false, "Invalid ImpactType!");
				return GroundContact;
		}
	}

	/**
	 * Get the contact of ContactType. Only Ground, Wall and Ceiling are valid options.
	 * @return True if the contact is valid.
	 */
	bool GetValidContact(EMovementImpactType ContactType, FMovementHitResult&out OutContact) const
	{
		switch(ContactType)
		{
			case EMovementImpactType::Ground:
			{
				OutContact = GroundContact;
				return OutContact.IsAnyGroundContact();
			}

			case EMovementImpactType::Wall:
			{
				OutContact = WallContact;
				return WallContact.IsWallImpact();
			}

			case EMovementImpactType::Ceiling:
			{
				OutContact = CeilingContact;
				return CeilingContact.IsCeilingImpact();
			}

			default:
				devError("Invalid ContactType");
				return false;
		}
	}

#if !RELEASE
	const TArray<FInstigator>& GetOverrideInstigators(EMovementImpactType ImpactType) const
	{
		switch(ImpactType)
		{
			case EMovementImpactType::Ground:
				return GroundContactOverrideInstigators;

			case EMovementImpactType::Wall:
				return WallContactOverrideInstigators;

			case EMovementImpactType::Ceiling:
				return CeilingContactOverrideInstigators;

			default:
				return GroundContactOverrideInstigators;
		}
	}

	void ClearOverrideInstigators()
	{
		GroundContactOverrideInstigators.Empty();
		WallContactOverrideInstigators.Empty();
		CeilingContactOverrideInstigators.Empty();
	}
#endif
};