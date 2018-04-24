/*
 * UniCrypt
 *
 *  UniCrypt(tm): Cryptographical framework allowing the implementation of cryptographic protocols e.g. e-voting
 *  Copyright (c) 2016 Bern University of Applied Sciences (BFH), Research Institute for
 *  Security in the Information Society (RISIS), E-Voting Group (EVG)
 *  Quellgasse 21, CH-2501 Biel, Switzerland
 *
 *  Licensed under Dual License consisting of:
 *  1. GNU Affero General Public License (AGPL) v3
 *  and
 *  2. Commercial license
 *
 *
 *  1. This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 *  2. Licensees holding valid commercial licenses for UniCrypt may use this file in
 *   accordance with the commercial license agreement provided with the
 *   Software or, alternatively, in accordance with the terms contained in
 *   a written agreement between you and Bern University of Applied Sciences (BFH), Research Institute for
 *   Security in the Information Society (RISIS), E-Voting Group (EVG)
 *   Quellgasse 21, CH-2501 Biel, Switzerland.
 *
 *
 *   For further information contact <e-mail: unicrypt@bfh.ch>
 *
 *
 * Redistributions of files must retain the above copyright notice.
 */
package ch.bfh.unicrypt.helper.random.deterministic;

import ch.bfh.unicrypt.helper.array.classes.ByteArray;
import ch.bfh.unicrypt.helper.hash.HashAlgorithm;
import ch.bfh.unicrypt.helper.random.RandomByteArraySequenceIterator;
import ch.bfh.unicrypt.helper.random.RandomOracle;

/**
 * This class is a counter mode (CTR) implementation of a deterministic random bit generator. The given hash algorithm
 * is applied repeatedly to {@code seed+i}, where {@code seed} is a byte array of length
 * {@code hashAlgorithm.getByteLength()} and {@code i=0,1,2,...} is a counter. Instances of this class are generated by
 * random oracles.
 * <p>
 * @author R. Haenni
 * @version 2.0
 * @see RandomOracle
 */
public class OFB_DRBG
	   extends DeterministicRandomByteArraySequence {

	private final HashAlgorithm hashAlgorithm;

	private OFB_DRBG(HashAlgorithm hashAlgorithm, ByteArray seed) {
		super(seed);
		this.hashAlgorithm = hashAlgorithm;
	}

	@Override
	public RandomByteArraySequenceIterator iterator() {

		return new RandomByteArraySequenceIterator() {

			private ByteArray state = seed;

			@Override
			public ByteArray abstractNext() {
				this.state = hashAlgorithm.getHashValue(this.state);
				return this.state;
			}

		};
	}

	/**
	 * Returns a new factory for constructing new instances of this class. It uses the default hash algorithm.
	 * <p>
	 * @return The new OFB_DRBG factory
	 */
	public static DeterministicRandomByteArraySequence.Factory getFactory() {
		return OFB_DRBG.getFactory(HashAlgorithm.getInstance());
	}

	/**
	 * For a given hash algorithm, this method returns a new factory for constructing new instances of this class.
	 * <p>
	 * @param hashAlgorithm The given hash algorithm
	 * @return The new OFB_DRBG factory
	 */
	public static DeterministicRandomByteArraySequence.Factory getFactory(final HashAlgorithm hashAlgorithm) {
		if (hashAlgorithm == null) {
			throw new IllegalArgumentException();
		}
		return new DeterministicRandomByteArraySequence.Factory() {

			@Override
			protected DeterministicRandomByteArraySequence abstractGetInstance(ByteArray seed) {
				return new OFB_DRBG(hashAlgorithm, seed);
			}

			@Override
			public int getSeedBitLength() {
				return hashAlgorithm.getBitLength();
			}

		};
	}

}
